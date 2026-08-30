#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 TWRP device tree for Infinix GT 30 Pro (X6873)
#
# SPDX-License-Identifier: Apache-2.0
#

DEVICE_PATH := device/infinix/X6873

# ============================================================================
# BRICK-SAFETY NOTES — read before changing anything here
#
# Every value below was measured from the device's own stock images
# (boot.img / init_boot.img / vendor_boot.img, X6873-OP 16.2.0.145SP03,
# kernel identical in 150SP12). Earlier community X6873 recovery trees
# bootlooped because of the specific mistakes called out in the comments.
# Do not "tidy" these values.
# ============================================================================

# For building with a minimal manifest
ALLOW_MISSING_DEPENDENCIES := true
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_MISSING_REQUIRED_MODULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES := true
BUILD_BROKEN_PREBUILT_ELF_FILES := true

# ---------------------------------------------------------------- platform
TARGET_BOARD_PLATFORM := mt6897
TARGET_BOOTLOADER_BOARD_NAME := x6873_h972
TARGET_NO_BOOTLOADER := true
BOARD_HAS_MTK_HARDWARE := true
BOARD_USES_MTK_HARDWARE := true

# ------------------------------------------------------------ architecture
# 64-bit only: stock ro.product.cpu.abilist32 is empty and zygote is zygote64.
# A 32-bit second arch here produces a recovery that tries to load 32-bit
# binaries the device cannot run.
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := generic
TARGET_CPU_VARIANT_RUNTIME := cortex-a76
TARGET_USES_64_BIT_BINDER := true

# ------------------------------------------------------------------ kernel
# GKI 2.0: boot.img holds ONLY the kernel (ramdisk_size = 0). TWRP must not
# try to build or repack a kernel.
TARGET_NO_KERNEL := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_RAMDISK_USE_LZ4 := true
BOARD_KERNEL_SEPARATED_DTBO := true

BOARD_BOOT_HEADER_VERSION := 4
BOARD_KERNEL_PAGESIZE := 4096
BOARD_HEADER_SIZE := 2128

# Load addresses.
#
# The stock vendor_boot v4 header stores ABSOLUTE addresses:
#     kernel  0x40000000
#     ramdisk 0x66f00000
#     tags    0x47c80000
#     dtb     0x47c80000
#
# base + offset must reproduce those exactly:
#     0x3fff8000 + 0x00008000 = 0x40000000   kernel
#     0x3fff8000 + 0x26f08000 = 0x66f00000   ramdisk
#     0x3fff8000 + 0x07c88000 = 0x47c80000   tags / dtb
#
# ROOT CAUSE OF THE KNOWN BOOTLOOP: hoshiyomiX/infinix_X6873-TWRP uses
# base 0x40078000 with ramdisk_offset 0x11088000, which resolves to kernel
# 0x40080000 and ramdisk 0x51100000. The ramdisk lands 0x15e00000 below where
# the bootloader expects it, so the kernel finds no ramdisk and reboots.
BOARD_KERNEL_BASE := 0x3fff8000
BOARD_KERNEL_OFFSET := 0x00008000
BOARD_RAMDISK_OFFSET := 0x26f08000
BOARD_KERNEL_TAGS_OFFSET := 0x07c88000
BOARD_TAGS_OFFSET := $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_DTB_OFFSET := 0x07c88000

# Stock vendor_boot cmdline, verbatim. Nothing appended.
# In particular NOT androidboot.selinux=permissive: on this device the stock
# vendor policy is loaded from the ramdisk, and forcing permissive changes
# first-stage init behaviour instead of fixing anything.
BOARD_KERNEL_CMDLINE := bootopt=64S3,32N2,64N2
BOARD_VENDOR_CMDLINE := $(BOARD_KERNEL_CMDLINE)

# DTB: the stock MT6897 DTB, byte-identical, taken from stock vendor_boot.
# It carries the MediaTek DT wrapper header (magic 1eabb7d7) the bootloader
# expects — do not strip it, and do not substitute a DTB from another device.
# BOARD_INCLUDE_DTB_IN_BOOTIMG defines the $(PRODUCT_OUT)/dtb.img target, but
# only BOARD_PREBUILT_DTBIMAGE_DIR supplies a RULE to build it (core/Makefile
# concatenates $(BOARD_PREBUILT_DTBIMAGE_DIR)/*.dtb). Setting the former
# without the latter is what produced run #5's
#   ninja: 'out/target/product/X6873/dtb.img' ... missing and no known rule
# BOARD_PREBUILT_DTBIMAGE (singular) is not an AOSP variable at all.
BOARD_PREBUILT_DTBIMAGE_DIR := $(DEVICE_PATH)/prebuilt/dtb
BOARD_INCLUDE_DTB_IN_BOOTIMG := true

BOARD_MKBOOTIMG_ARGS += --base $(BOARD_KERNEL_BASE)
BOARD_MKBOOTIMG_ARGS += --pagesize $(BOARD_KERNEL_PAGESIZE)
BOARD_MKBOOTIMG_ARGS += --kernel_offset $(BOARD_KERNEL_OFFSET)
BOARD_MKBOOTIMG_ARGS += --ramdisk_offset $(BOARD_RAMDISK_OFFSET)
BOARD_MKBOOTIMG_ARGS += --tags_offset $(BOARD_KERNEL_TAGS_OFFSET)
BOARD_MKBOOTIMG_ARGS += --dtb_offset $(BOARD_DTB_OFFSET)
BOARD_MKBOOTIMG_ARGS += --header_version $(BOARD_BOOT_HEADER_VERSION)
BOARD_MKBOOTIMG_ARGS += --board ""
BOARD_MKBOOTIMG_ARGS += --vendor_cmdline $(BOARD_VENDOR_CMDLINE)

# -------------------------------------------------------------- partitions
BOARD_FLASH_BLOCK_SIZE := 262144
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_INIT_BOOT_IMAGE_PARTITION_SIZE := 8388608
BOARD_HAS_LARGE_FILESYSTEM := true
BOARD_SUPER_PARTITION_GROUPS := infinix_dynamic_partitions
BOARD_INFINIX_DYNAMIC_PARTITIONS_PARTITION_LIST := system system_ext vendor product odm
BOARD_USES_METADATA_PARTITION := true

TARGET_USERIMAGES_USE_EXT4 := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USES_MKE2FS := true
BOARD_USERDATAIMAGE_FILE_SYSTEM_TYPE := f2fs

# ---------------------------------------------------------------- recovery
# There is NO dedicated recovery partition. Recovery lives in vendor_boot as
# the RECOVERY ramdisk fragment, which is what stock does.
TARGET_NO_RECOVERY := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT := true
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true

# Leave this EMPTY. The stock fstab requests
# avb_keys=/avb/{q,r,s}-gsi.avbpubkey, and moving GSI keys into vendor_boot on
# a device whose vbmeta we are not resigning causes first_stage_mount to fail
# verification and reboot.
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT :=

TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery/root/system/etc/recovery.fstab

# Stock recovery graphics format. RGBX_8888 (used by every earlier X6873 tree)
# gives swapped red/blue channels on this panel.
TARGET_RECOVERY_PIXEL_FORMAT := BGRA_8888

# --------------------------------------------------------------------- AVB
# Recovery is not a separate partition here, so there is no recovery vbmeta
# to sign. Earlier trees set BOARD_AVB_RECOVERY_* with rollback index
# location 1 — the same location the real vbmeta_system chain uses on this
# device. Writing a descriptor there is what turns a bootloop into a
# verification failure that needs fastboot to recover.
#
# We do not resign or regenerate any vbmeta. Only vendor_boot is flashed, and
# the device must be unlocked (its stock vbmeta then does not gate boot).
BOARD_AVB_ENABLE := false

# ---------------------------------------------------------------- versions
# PLATFORM_VERSION 99.87.36 with PLATFORM_SECURITY_PATCH 2099-12-31 is a TWRP
# convention to defeat the anti-rollback check. It is kept, but note it also
# makes PLATFORM_SECURITY_PATCH_TIMESTAMP enormous — which is exactly why
# using that value as an AVB rollback index (as earlier trees did) is
# dangerous. With AVB disabled above, it is inert.
PLATFORM_VERSION := 99.87.36
PLATFORM_VERSION_LAST_STABLE := $(PLATFORM_VERSION)
PLATFORM_SECURITY_PATCH := 2099-12-31
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)
BOOT_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# ----------------------------------------------------------------- display
# Panel: vtdr6126a, 1224x2720, DSI video mode, up to 144 Hz, density 480.
# Earlier trees declared 1080x2400 / 120 Hz, which is a different panel.
TARGET_SCREEN_WIDTH := 1224
TARGET_SCREEN_HEIGHT := 2720
TARGET_SCREEN_DENSITY := 480

TW_THEME := portrait_hdpi
TW_FRAMERATE := 60
TW_NO_SCREEN_BLANK := true
TW_BRIGHTNESS_PATH := "/sys/class/leds/lcd-backlight/brightness"
TW_MAX_BRIGHTNESS := 2047
TW_DEFAULT_BRIGHTNESS := 1200

# --------------------------------------------------------------------- USB
# Stock recovery init sets exactly these two properties.
TW_EXCLUDE_DEFAULT_USB_INIT := true
TW_USB_STORAGE := true

# --------------------------------------------------------------- crypto
# FBE with metadata encryption, aes-256-xts:aes-256-cts:v2, F2FS userdata.
TW_INCLUDE_CRYPTO := true
TW_INCLUDE_CRYPTO_FBE := true
TW_INCLUDE_FBE_METADATA_DECRYPT := true
TW_USE_FSCRYPT_POLICY := 2
TW_INCLUDE_LIBRESETPROP := true
TW_INCLUDE_RESETPROP := true

# ------------------------------------------------------------------- misc
TW_HAS_NO_RECOVERY_PARTITION := true
TW_INCLUDE_FASTBOOTD := true
TW_INCLUDE_REPACKTOOLS := true
TW_INCLUDE_NTFS_3G := true
TW_EXTRA_LANGUAGES := true
TW_HAS_NO_SELECT_BUTTON := true
BOARD_SUPPRESS_SECURE_ERASE := true
TARGET_USES_LOGD := true
TWRP_INCLUDE_LOGCAT := true

# lptools can resize and delete logical partitions from the GUI. On a device
# whose super layout we have not fully verified, that is a data-loss risk.
TW_EXCLUDE_LPTOOLS := true
TW_EXCLUDE_APEX := true

# Kernel modules for the recovery ramdisk are supplied by the workflow, which
# extracts them from the stock vendor_boot image at build time. See
# tools/ and docs/ in this repository.
TW_LOAD_VENDOR_BOOT_MODULES := true

TW_DEVICE_VERSION := X6873-brick-safe-1
