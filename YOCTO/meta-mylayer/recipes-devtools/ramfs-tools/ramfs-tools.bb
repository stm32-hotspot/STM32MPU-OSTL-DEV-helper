# Copyright (C) 2017, STMicroelectronics - All Rights Reserved
# Released under the MIT license (see COPYING.MIT for the terms)

SUMMARY = "Script for running a ramfs STM32MP2 system"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COREBASE}/meta/files/common-licenses/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
DEPENDS += "u-boot-tools "

SRC_URI = "file://Flashlayout_ramfs.tsv \
	   file://run_ramfs.bat \
	   file://script.cmd \
	   file://script.txt"

BBCLASSEXTEND = "native nativesdk"

RDEPENDS:${PN}:append = " bash "

# RRECOMMENDS:${PN}:append:class-nativesdk = " nativesdk-gptfdisk "

inherit deploy

SCRIPT_DEPLOYDIR ?= "scripts"

do_compile () {
    cd ${WORKDIR}
    mkimage -C none -A arm -T script -d script.cmd script.bin
}

do_install() {
    install -d ${D}/${bindir}
    install -m 0755 ${WORKDIR}/Flashlayout_ramfs.tsv ${D}/${bindir}
    install -m 0755 ${WORKDIR}/run_ramfs.bat ${D}/${bindir}
    install -m 0755 ${WORKDIR}/script.bin ${D}/${bindir}
    install -m 0755 ${WORKDIR}/script.cmd ${D}/${bindir}
    install -m 0755 ${WORKDIR}/script.txt ${D}/${bindir}
}

do_deploy() {
    :
}

do_deploy:class-native() {
    install -d ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}
    install -m 0755 ${WORKDIR}/Flashlayout_ramfs.tsv ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}/
    install -m 0755 ${WORKDIR}/run_ramfs.bat ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}/
    install -m 0755 ${WORKDIR}/script.bin ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}/
    install -m 0755 ${WORKDIR}/script.cmd ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}/
    install -m 0755 ${WORKDIR}/script.txt ${DEPLOYDIR}/${SCRIPT_DEPLOYDIR}/
}
addtask deploy before do_build after do_compile
