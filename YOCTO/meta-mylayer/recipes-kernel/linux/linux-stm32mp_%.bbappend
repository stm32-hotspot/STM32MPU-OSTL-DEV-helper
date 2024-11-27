FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://fragment-06-minimal.config;subdir=fragments"

KERNEL_CONFIG_FRAGMENTS:append:stm32mp2common = " ${WORKDIR}/fragments/fragment-06-minimal.config"

