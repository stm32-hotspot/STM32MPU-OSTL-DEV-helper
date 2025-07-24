#!/bin/bash -e

STM32MP_PLATFORM="stm32mp1"
# MP15
# SOC_BASE="stm32mp15"
# SOC="${SOC_BASE}7c"

# MP13
SOC_BASE="stm32mp13"
SOC="${SOC_BASE}5f"

### DTS name (external dts, can be a custom name) ###
## ST board DTS names
# CUSTOM_DTS_NAME="${SOC}-ev1"
# CUSTOM_DTS_NAME="${SOC}-dk2"
# CUSTOM_DTS_NAME="${SOC}-dk"
# CUSTOM_DTS_NAME="${SOC}-dk-v6.0-mx"

CUSTOM_DTS_NAME="${SOC}-myboard"

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
SOURCES_BASE_PATH="./"
SDK_BUILD_ENV_BASE="/opt/st/${STM32MP_PLATFORM}/5.0.8-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11"
SDK_BUILD_ENV_PATH="${SDK_BUILD_ENV_BASE}/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi"
source ${SDK_BUILD_ENV_PATH}

EXTDT_WORKING_DIR="STM32MPU-OSTL-DEV-helper/DEVICETREE/EXT_DTS_FOR_MY_STM32MP135F-DK"

MINIMAL_DEFCONFIG="0"

SDK_HELPER_OUT_KERNEL="BUILD_OUTPUT/kernel/"
mkdir -p ${SDK_HELPER_OUT_KERNEL}

LINUX_DIR="linux-stm32mp-6.6.78-stm32mp-r2-r0/linux-6.6.78/"

KERNEL_CONFIG_DIR="../../STM32MPU-OSTL-DEV-helper/TEMPLATES/STM32MP1/CONFIGS/KERNEL"
DEBUG_FILE='> kernel_config.log 2>&1'

mkdir -p ${SDK_HELPER_OUT_KERNEL}

FRAGMENT_LIST=" fragment-04-modules.config \
		fragment-03-systemd.config"

cd ${SOURCES_BASE_PATH}
CURDIR=`pwd`

if [ -z "${EXTDT_WORKING_DIR}" ]; then
   EXTDT_DIR="${CURDIR}/${EXTERNAL_DT_DIR}"
 else
   for d in tf-a optee u-boot; do
     [[ ! -d "${EXTDT_WORKING_DIR}/${d}" ]] && echo -e "\n\tError: folder ${EXTDT_WORKING_DIR}/${d} does not exist, please correct the path\n\n" && exit 0
   done
   EXTDT_DIR="${CURDIR}/${EXTDT_WORKING_DIR}"
fi

cd ${LINUX_DIR}

export K_BUILD_DIR="../build/"
mkdir -p ${K_BUILD_DIR}

make O=${K_BUILD_DIR} multi_v7_defconfig fragment-0*.config >> kernel_config.log

if [ "x${MINIMAL_DEFCONFIG}" = "x0" ]; then
   echo
   for frag in ${FRAGMENT_LIST}; do
     ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../${frag} >> kernel_config.log
   done
 else
    ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config \
           ${KERNEL_CONFIG_DIR}/fragment_minimal.config >> kernel_config.log 2>&1
fi

(yes '' || true) | make O=${K_BUILD_DIR} oldconfig >> kernel_config.log

# ./scripts/diffconfig -m  ${K_BUILD_DIR}.config ${K_BUILD_DIR}defconfig_202411292314 ${DEBUG_FILE}
# exit 0

## Uncomment below line to generate a new kernel fragment file
# ./scripts/diffconfig -m ${K_BUILD_DIR}defconfig ${KERNEL_CONFIG_DIR}/old_defconfig > ${KERNEL_CONFIG_DIR}/fragment_minimal.config
# exit 0

## Uncomment below line if you want to use minimal_defconfig file for kernel configuration
# cp ${KERNEL_CONFIG_DIR}/minimal_defconfig arch/arm/configs/stm32mp1_minimal_defconfig
# make O=${K_BUILD_DIR} stm32mp1_minimal_defconfig

# make O=${K_BUILD_DIR} menuconfig
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
