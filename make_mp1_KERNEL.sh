#!/bin/bash -e

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
export ARCH=arm64
SDK_BUILD_ENV_PATH="/opt/st/stm32mp1/5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi"
source ${SDK_BUILD_ENV_PATH}

SOC_BASE="stm32mp13"
SOC="${SOC_BASE}5f"
CUSTOM_DTS_NAME="${SOC}-dk"
# CUSTOM_DTS_NAME="${SOC}-dk-v6.0-mx"

MINIMAL_DEFCONFIG="0"

SDK_HELPER_OUT_KERNEL="BUILD_OUTPUT/kernel/"
mkdir -p ${SDK_HELPER_OUT_KERNEL}

LINUX_DIR="linux-stm32mp-6.6.48-stm32mp-r1-r0/linux-6.6.48/"

KERNEL_CONFIG_DIR="../../STM32MPU-OSTL-DEV-helper/TEMPLATES/STM32MP1/CONFIGS/KERNEL"
DEBUG_FILE='> kernel_config.log 2>&1'

mkdir -p ${SDK_HELPER_OUT_KERNEL}

FRAGMENT_LIST=" optional-fragment-05-signature.config \
		optional-fragment-06-nosmp.config \
		optional-fragment-07-efi.config"

cd ${LINUX_DIR}

export K_BUILD_DIR="../build/"
mkdir -p ${K_BUILD_DIR}

# make O=${K_BUILD_DIR} multi_v7_defconfig 

# if [ "x${MINIMAL_DEFCONFIG}" = "x0" ]; then
#   echo
#   for frag in ${FRAGMENT_LIST}; do
#     ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../${frag}
#   done
# else
#    ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config \
#           ${KERNEL_CONFIG_DIR}/fragment_minimal.config >> kernel_config.log 2>&1
# fi

# (yes '' || true) | make O=${K_BUILD_DIR} oldconfig

# ./scripts/diffconfig -m  ${K_BUILD_DIR}.config ${K_BUILD_DIR}defconfig_202411292314 ${DEBUG_FILE}
# exit 0

## Uncomment below line to generate a new kernel fragment file
# ./scripts/diffconfig -m ${K_BUILD_DIR}defconfig ${KERNEL_CONFIG_DIR}/old_defconfig > ${KERNEL_CONFIG_DIR}/fragment_minimal.config
# exit 0

## Uncomment below line if you want to use minimal_defconfig file for kernel configuration
# cp ${KERNEL_CONFIG_DIR}/minimal_defconfig arch/arm/configs/stm32mp1_minimal_defconfig
# make O=${K_BUILD_DIR} stm32mp1_minimal_defconfig

make O=${K_BUILD_DIR} menuconfig
# make O=${K_BUILD_DIR} savedefconfig
# cp -v ${K_BUILD_DIR}/defconfig  ${K_BUILD_DIR}/defconfig_`date +%Y%m%d%H%M`
# exit 0

make O=${K_BUILD_DIR} KBUILD_EXTDTS="${EXTDT_DIR}/linux" st/${CUSTOM_DTS_NAME}.dtb

make LOADADDR=0xc2000040 O=${K_BUILD_DIR} -j8 uImage
# make O=${K_BUILD_DIR} -j8 modules
# make O=${K_BUILD_DIR} INSTALL_MOD_PATH="../../${SDK_HELPER_OUT_KERNEL}" modules_install

cp -v ${K_BUILD_DIR}arch/arm/boot/uImage ../../${SDK_HELPER_OUT_KERNEL}
cp -v ${K_BUILD_DIR}arch/arm/boot/dts/st/${CUSTOM_DTS_NAME}.dtb ../../${SDK_HELPER_OUT_KERNEL}
rm -f ../../${SDK_HELPER_OUT_KERNEL}/lib/modules/6.6.48/build

