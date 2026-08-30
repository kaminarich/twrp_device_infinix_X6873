#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 TWRP device tree for Infinix GT 30 Pro (X6873)
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
# core_64_bit_only: the device has no 32-bit ABI at all.
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/base.mk)

# Enable project quotas and casefolding for emulated storage without sdcardfs
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

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
