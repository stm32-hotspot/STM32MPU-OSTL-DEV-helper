SUMMARY = "My minimal image"
LICENSE  = "MIT"

include recipes-st/images/st-image.inc

inherit core-image

IMAGE_ROOTFS_MAXSIZE = "33554432"
IMAGE_FSTYPES += "${INITRAMFS_FSTYPES}"

PACKAGE_INSTALL += " \
    kernel-imagebootfs \
"
IMAGE_FEATURES = ""
CORE_IMAGE_EXTRA_INSTALL = ""
