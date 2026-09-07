#!/usr/bin/env bash
# Uploads the grafted vendor_boot image to pixeldrain and writes the resulting
# links to $GITHUB_ENV so the Telegram reporter can include them.
#
# Reads PIXELDRAIN_KEY from the environment (a repository secret). The key is
# passed to curl through a config file on stdin rather than on the command line,
# so it never appears in the process list, and it is never echoed.
#
# Uploads ONLY the built recovery image. Nothing else in the workspace is ever
# sent anywhere.
set -u

IMG="$HOME/artifact/vendor_boot-twrp-X6873.img"

if [ -z "${PIXELDRAIN_KEY:-}" ]; then
  echo "PIXELDRAIN_KEY not configured; skipping upload."
  exit 0
fi

if [ ! -f "$IMG" ]; then
  echo "No grafted image at $IMG; nothing to upload."
  exit 0
fi

SIZE=$(stat -c%s "$IMG")
NAME="vendor_boot-twrp-X6873-r${GITHUB_RUN_NUMBER}.img"
echo "uploading $NAME ($SIZE bytes) to pixeldrain"

# -F name=... sets the stored filename; --config - keeps the key out of argv.
RESP=$(printf 'user = ":%s"\n' "$PIXELDRAIN_KEY" | \
  curl -sS --retry 3 --max-time 900 --config - \
    -X POST \
    -F "name=${NAME}" \
    -F "file=@${IMG};filename=${NAME}" \
    https://pixeldrain.com/api/file)

# Response is JSON: {"id":"xxxxxxx"} on success, {"success":false,...} on error.
ID=$(printf '%s' "$RESP" | python3 -c 'import json,sys
try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(0)
print(d.get("id", ""))' 2>/dev/null)

if [ -z "$ID" ]; then
  echo "pixeldrain upload failed. Response:"
  # Safe to print: the response contains no credentials.
  printf '%s\n' "$RESP" | head -c 500
  {
    echo "PD_STATUS=failed"
  } >> "$GITHUB_ENV"
  exit 0
fi

VIEW="https://pixeldrain.com/u/${ID}"
DIRECT="https://pixeldrain.com/api/file/${ID}?download"

echo "pixeldrain id: $ID"
echo "view:   $VIEW"
echo "direct: $DIRECT"

{
  echo "PD_STATUS=ok"
  echo "PD_ID=${ID}"
  echo "PD_VIEW=${VIEW}"
  echo "PD_DIRECT=${DIRECT}"
  echo "PD_NAME=${NAME}"
} >> "$GITHUB_ENV"

{
  echo "## pixeldrain"
  echo "- file: \`${NAME}\` (${SIZE} bytes)"
  echo "- view: ${VIEW}"
  echo "- direct: ${DIRECT}"
} >> "$GITHUB_STEP_SUMMARY"
