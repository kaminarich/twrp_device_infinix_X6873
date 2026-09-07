#!/usr/bin/env bash
# Telegram reporter for the X6873 TWRP build.
#
# Reads TG_BOT (bot token) and TG_CHAT (chat id) from the environment, which
# the workflow provides from repository secrets or variables. The token is
# never echoed and never appears in a logged URL.
#
# On success: sends the grafted vendor_boot image plus a detailed report.
# On failure: sends the report with the tail of the build log.
set -u

API="https://api.telegram.org/bot${TG_BOT}"
OUT=/mnt/twrp/out/target/product/X6873

# ---------------------------------------------------------------- preflight
# A bot can only post to a chat it belongs to. Verify before doing work, and
# never fail the build over a chat misconfiguration -- the image is already
# uploaded and archived by the time this runs.
PRE=$(curl -sS --max-time 30 "${API}/getChat?chat_id=${TG_CHAT}" 2>/dev/null)
if ! printf '%s' "$PRE" | python3 -c 'import json,sys; sys.exit(0 if json.load(sys.stdin).get("ok") else 1)' 2>/dev/null; then
  DESC=$(printf '%s' "$PRE" | python3 -c 'import json,sys
try: print(json.load(sys.stdin).get("description","unparseable response"))
except Exception: print("unparseable response")' 2>/dev/null)
  BOT=$(curl -sS --max-time 30 "${API}/getMe" 2>/dev/null | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin)
    print("@"+d["result"]["username"] if d.get("ok") else "INVALID TOKEN")
except Exception: print("unknown")' 2>/dev/null)
  echo "::warning::Telegram not reachable: ${DESC}"
  echo "Bot identity: ${BOT}"
  echo "chat_id used: ${TG_CHAT}"
  echo
  echo "Most likely cause: the bot is not a member of that chat."
  echo "Fix: add ${BOT} to the group (or make it an admin if it is a channel),"
  echo "then send one message there and re-run. The build artifacts and the"
  echo "pixeldrain link are unaffected."
  exit 0
fi

tg_send() { # $1 = text
  curl -fsS --retry 3 --max-time 60 \
    -H "Content-Type: application/json" \
    -d "$(python3 -c 'import json,sys; print(json.dumps({"chat_id": int(sys.argv[1]), "text": sys.argv[2], "parse_mode": "HTML", "disable_web_page_preview": True}))' "$TG_CHAT" "$1")" \
    "${API}/sendMessage" > /dev/null
}

tg_doc() { # $1 = file, $2 = caption
  curl -fsS --retry 3 --max-time 300 \
    -F "chat_id=${TG_CHAT}" \
    -F "caption=${2}" \
    -F "document=@${1}" \
    "${API}/sendDocument" > /dev/null
}

# ------------------------------------------------------------------ facts
RUN_URL="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
SHA="${GITHUB_SHA:0:9}"
GRAFTED="$HOME/artifact/vendor_boot-twrp-X6873.img"

# pixeldrain links are exported by tools/pixeldrain_upload.sh via GITHUB_ENV
if [ "${PD_STATUS:-}" = "ok" ]; then
  PD_LINE="${PD_VIEW}
<b>Direct:</b> ${PD_DIRECT}"
else
  PD_LINE="<i>pixeldrain upload unavailable — use the run artifacts</i>"
fi


if [ -f "$HOME/build.log" ]; then
  BUILT_FOR="$(grep -oE '#### (built|failed to build) some targets \([0-9:]+ ' "$HOME/build.log" | tail -1)"
  FAILED_TARGETS="$(grep -cE '^FAILED:' "$HOME/build.log" || true)"
  LAST_ERROR="$(grep -E '^FAILED:' "$HOME/build.log" | head -1 | cut -c1-200)"
fi

# ------------------------------------------------------------------ report
if [ -f "$GRAFTED" ]; then
  GRAFT_SUMMARY="$(grep -E 'preserved|wrote|VERIFIED' "$HOME/graft.log" 2>/dev/null | tr '\n' ' ' | cut -c1-300)"
  IMG_SIZE="$(stat -c%s "$GRAFTED")"
  IMG_SHA="$(sha256sum "$GRAFTED" | cut -d' ' -f1 | cut -c1-16)"

  REPORT="✅ <b>TWRP vendor_boot build succeeded</b>
<b>Device:</b> Infinix GT 30 Pro (X6873)
<b>Commit:</b> <code>${SHA}</code>
<b>Product:</b> twrp_X6873-eng (twrp-12.1)
<b>Duration:</b> ${BUILT_FOR:-n/a}

<b>Artifact:</b> vendor_boot-twrp-X6873.img
<b>Size:</b> $(( IMG_SIZE / 1024 / 1024 )) MB ($IMG_SIZE bytes)
<b>SHA-256:</b> <code>${IMG_SHA}…</code>

<b>Graft verification:</b>
${GRAFT_SUMMARY:-<i>see workflow summary</i>}

<b>Download:</b> ${PD_LINE}

<b>Flash — this device REQUIRES vbmeta verification off.</b>
Its stock root vbmeta.img has a direct HASH descriptor for vendor_boot
(image_size=32489472, sha256), so libavb hashes the partition itself and any
change fails verification.
<code>fastboot --disable-verity --disable-verification flash vbmeta vbmeta.img</code>
<code>fastboot flash vendor_boot ${PD_NAME:-vendor_boot-twrp-X6873.img}</code>
<code>fastboot reboot recovery</code>
Never flash the RAW image. Do not re-lock the bootloader.
<b>Run:</b> ${RUN_URL}"

  tg_send "$REPORT"
  # Telegram caps bot documents at 50 MB. The padded image is 64 MiB, so it is
  # delivered via pixeldrain instead of being attached.
  if [ "$IMG_SIZE" -lt 49000000 ]; then
    tg_doc "$GRAFTED" "TWRP vendor_boot for X6873 — flash to vendor_boot only. Commit ${SHA}"
  else
    tg_send "ℹ️ The image is $(( IMG_SIZE / 1024 / 1024 )) MB, above Telegram's 50 MB bot limit, so it is not attached. Use the pixeldrain link above (resumable) or the run artifacts."
  fi
  # Always attach the small logs so failures are diagnosable from the chat.
  [ -f "$HOME/graft.log" ] && tg_doc "$HOME/graft.log" "graft verification — run ${GITHUB_RUN_NUMBER}"
else
  REPORT="❌ <b>TWRP vendor_boot build FAILED</b>
<b>Device:</b> Infinix GT 30 Pro (X6873)
<b>Commit:</b> <code>${SHA}</code>
<b>Product:</b> twrp_X6873-eng (twrp-12.1)
<b>Duration:</b> ${BUILT_FOR:-n/a}
<b>Failed targets:</b> ${FAILED_TARGETS:-unknown}
<b>First failure:</b>
<code>${LAST_ERROR:-no FAILED: lines found; see artifacts}</code>

Full build log is in the run artifacts.
<b>Run:</b> ${RUN_URL}"

  tg_send "$REPORT"

  # Attach the log tail so the cause is readable without opening GitHub.
  if [ -f "$HOME/build.log" ]; then
    tail -c 200000 "$HOME/build.log" > /tmp/build-tail.log
    gzip -f /tmp/build-tail.log
    tg_doc /tmp/build-tail.log.gz "build.log tail — X6873 TWRP run ${GITHUB_RUN_NUMBER}"
  fi
fi

echo "Telegram report sent."
