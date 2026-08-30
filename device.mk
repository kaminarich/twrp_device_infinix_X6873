#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/infinix/X6873

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# A/B — this device is Virtual A/B. Recovery needs the boot control HAL to
# read and set the active slot, otherwise "Reboot > Slot A/B" is missing and
# an OTA sideload cannot switch slots.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += boot init_boot vendor_boot

# Module names verified against bootctrl/Android.bp in this tree:
#   name: android.hardware.boot@1.2-mtkimpl  (recovery_available: true)
PRODUCT_PACKAGES += \
    android.hardware.boot@1.2-mtkimpl.recovery \
    android.hardware.boot@1.2-impl.recovery

# Virtual A/B snapshot handling. Without snapuserd in the ramdisk, recovery
# cannot mount a device that has a pending snapshot merge, which looks like a
# broken /data.
PRODUCT_PACKAGES += \
    snapuserd.recovery

# Filesystem tools. F2FS is required: userdata is f2fs on this device.
PRODUCT_PACKAGES += \
    mke2fs \
    e2fsck \
    make_f2fs \
    fsck.f2fs \
    resize.f2fs

# Health HAL, so the battery indicator works in recovery
PRODUCT_PACKAGES += \
    android.hardware.health@2.1-impl.recovery

# MediaTek partition-link helper. Stock recovery init runs
# /system/bin/mtk_plpath_utils; without an equivalent, /dev/block/by-name
# symlinks for logical partitions may be missing.
PRODUCT_PACKAGES += \
    mtk_plpath_utils.recovery

# Recovery ramdisk files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6897.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6897.rc \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6897:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6897
