## SUMMARY = "Provides Device Tree files for STM32MP257 myboard"
## LICENSE = "GPL-2.0-only"
## LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/GPL-2.0-only;md5=801f80980d171dd6425610833a22dbe6"

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI = " \
		file://devicetree/License.md \
		file://devicetree/README.md \
		file://devicetree/SECURITY.md \
		file://devicetree/linux/Makefile \
		file://devicetree/linux/stm32mp257f-myboard.dts \
		file://devicetree/linux/stm32mp257f-myboard-resmem.dtsi \
		file://devicetree/optee/conf.mk \
		file://devicetree/optee/stm32mp257f-myboard.dts \
		file://devicetree/optee/stm32mp257f-myboard-rcc.dtsi \
		file://devicetree/optee/stm32mp257f-myboard-resmem.dtsi \
		file://devicetree/optee/stm32mp257f-myboard-rif.dtsi \
		file://devicetree/tf-a/stm32mp257f-myboard.dts \
		file://devicetree/tf-a/stm32mp257f-myboard-fw-config.dts \
		file://devicetree/tf-a/stm32mp257f-myboard-fw-config.dtsi \
		file://devicetree/tf-a/stm32mp257f-myboard-rcc.dtsi \
		file://devicetree/u-boot/Makefile \
		file://devicetree/u-boot/stm32mp257f-myboard.dts \
		file://devicetree/u-boot/stm32mp257f-myboard-resmem.dtsi \
		file://devicetree/u-boot/stm32mp257f-myboard-u-boot.dtsi \
	"

S = "${WORKDIR}/devicetree"
