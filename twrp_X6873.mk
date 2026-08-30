#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 TWRP device tree for Infinix GT 30 Pro (X6873)
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
#
# core_64_bit.mk, not core_64_bit_only.mk: TWRP 12.1 still builds some 32-bit
# recovery libraries, and the "only" variant conflicts with that. The device is
# 64-bit only for Android, which is expressed in BoardConfig.mk instead.
#
# base.mk is deliberately NOT inherited: it pulls in the generic_system.mk
# artifact path requirements, and a recovery build installs TWRP binaries into
# system/, which then fails artifact_path_requirements.mk. full_base_telephony
# is what the working X6873 and duchamp TWRP trees use.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# A recovery image is not a GSI-compliant system image, so the artifact path
# requirements inherited from the AOSP product chain do not apply.
PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS := false

# NOTE: gsi_keys.mk is deliberately NOT inherited. Installing GSI AVB keys
# into a ramdisk for a device whose vbmeta we do not resign makes
# first_stage_mount fail verification.

# Inherit from the device
$(call inherit-product, device/infinix/X6873/device.mk)

# Inherit some common TWRP stuff
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := X6873
PRODUCT_NAME := twrp_X6873
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix GT 30 Pro
PRODUCT_MANUFACTURER := INFINIX

PRODUCT_GMS_CLIENTID_BASE := android-transsion

PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true
