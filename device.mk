#
# Copyright (C) 2026 The Android Open Source Project
#
# SPDX-License-Identifier: Apache-2.0
#

LOCAL_PATH := device/infinix/X6873

PRODUCT_SOONG_NAMESPACES += $(LOCAL_PATH)

# A/B — this device is Virtual A/B.
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += boot init_boot vendor_boot

# ===========================================================================
# Boot control and health HALs are deliberately NOT built into the recovery
# ramdisk. This is the fix for run #7.
#
# Run #7 reached target 20263/20265 and then failed with:
#     could not make way for new symlink: root/vendor
#     cannot delete non-empty directory: root/vendor
#     rsync error: ... (code 23)
#
# Why: the .recovery variants of these HALs install into
#     recovery/root/vendor/bin/hw/
#     recovery/root/vendor/etc/vintf/manifest/android.hardware.boot@1.1.xml
#     recovery/root/vendor/etc/vintf/manifest/android.hardware.boot@1.2.xml
#     recovery/root/vendor/etc/vintf/manifest/android.hardware.health@2.1.xml
# which turns recovery/root/vendor into a real, non-empty directory. The
# recovery packaging rule (core/Makefile:2230) then rsyncs the baseline
# $(TARGET_ROOT_OUT) over it, and in that baseline "vendor" is a SYMLINK.
# rsync cannot replace a non-empty directory with a symlink, so it exits 23.
# AOSP already hardcodes --exclude=cache in that same rsync for this exact
# class of collision, but provides no hook to add "vendor".
#
# Not building them costs nothing on this device. The stock PLATFORM vendor
# ramdisk already ships the recovery variants, and recovery mode loads
# PLATFORM merged with RECOVERY (verified in the stock image):
#     system/bin/hw/android.hardware.boot-service.mtk_recovery
#     system/bin/hw/android.hardware.health-service.example_recovery
#     system/lib64/lib_healthinfo_recovery.so
#     system/etc/init/android.hardware.boot-service.mtk_recovery.rc
#     system/etc/init/android.hardware.health-service.example_recovery.rc
# so A/B slot control and the battery indicator come from stock.
#
# bootctrl/ is still kept in this tree: it documents the MediaTek boot
# control implementation for this SoC and can be enabled later if the stock
# service turns out to be unusable.
# ===========================================================================

# Virtual A/B snapshot handling. Without snapuserd in the ramdisk, recovery
# cannot mount a device that has a pending snapshot merge, which looks like a
# broken /data. This installs into system/bin, not vendor/, so it is safe.
PRODUCT_PACKAGES += \
    snapuserd.recovery

# Filesystem tools. F2FS is required: userdata is f2fs on this device.
PRODUCT_PACKAGES += \
    mke2fs \
    e2fsck \
    make_f2fs \
    fsck.f2fs \
    resize.f2fs

# MediaTek partition-link helper. Stock recovery init runs
# /system/bin/mtk_plpath_utils; without an equivalent, /dev/block/by-name
# symlinks for logical partitions may be missing. Installs into system/bin.
PRODUCT_PACKAGES += \
    mtk_plpath_utils.recovery

# Recovery ramdisk files
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery/root/init.recovery.mt6897.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.mt6897.rc \
    $(LOCAL_PATH)/recovery/root/first_stage_ramdisk/fstab.mt6897:$(TARGET_COPY_OUT_RECOVERY)/root/first_stage_ramdisk/fstab.mt6897
