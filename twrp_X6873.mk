#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 TWRP device tree for Infinix GT 30 Pro (X6873)
#
# SPDX-License-Identifier: Apache-2.0
#

# Inherit from those products. Most specific first.
#
# Deliberately MINIMAL, and this matters.
#
# Run #3 failed in artifact_path_requirements.mk:
#   ... produces files inside build/make/target/product/generic_system.mk's
#   artifact path requirement
# because the AOSP product chain (base.mk / full_base_telephony.mk) calls
# require-artifacts-in-path for generic_system, and a recovery build installs
# TWRP binaries into system/ by design, which violates it.
#
# PRODUCT_ENFORCE_ARTIFACT_PATH_REQUIREMENTS cannot switch this off: the check
# runs whenever that variable is non-empty, so even ":= false" enables it
# (artifact_path_requirements.mk line 49: "$(if $(enforcement),...)").
#
# CORRECTION (run #6): the artifact path requirement was NOT caused by
# base.mk. It came from building the wrong product entirely -- lunch ran in a
# pipeline, so every build fell back to aosp_arm, which inherits
# generic_system.mk and calls require-artifacts-in-path. Verified that none of
# full_base_telephony -> full_base -> generic_no_telephony -> base.mk calls it.
#
# Minimal inheritance then caused a different failure: nothing populated
# $(TARGET_ROOT_OUT), and the recovery packaging rule rsyncs
# out/target/product/X6873/root into .../recovery, which failed with
# "No such file or directory".
#
# This is the inheritance hoshiyomiX's X6873 tree uses -- that tree's only real
# defect was its load addresses, so its product setup is sound.
# gsi_keys.mk is still deliberately excluded (see BoardConfig.mk).
$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)

# Inherit from the device
$(call inherit-product, device/infinix/X6873/device.mk)

# Inherit some common TWRP stuff (brings TWRP's package set)
$(call inherit-product, vendor/twrp/config/common.mk)

PRODUCT_DEVICE := X6873
PRODUCT_NAME := twrp_X6873
PRODUCT_BRAND := Infinix
PRODUCT_MODEL := Infinix GT 30 Pro
PRODUCT_MANUFACTURER := INFINIX

PRODUCT_GMS_CLIENTID_BASE := android-transsion

PRODUCT_PROPERTY_OVERRIDES += \
    ro.twrp.vendor_boot=true
