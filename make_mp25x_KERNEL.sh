#!/bin/bash -e

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
export ARCH=arm64
SDK_BUILD_ENV_PATH="/opt/st/stm32mp2/5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/environment-setup-cortexa35-ostl-linux"
source ${SDK_BUILD_ENV_PATH}

SOC_BASE="stm32mp25"
SOC="${SOC_BASE}7f"
# CUSTOM_DTS_NAME="${SOC}-ev1"
# CUSTOM_DTS_NAME="${SOC}-dk"
# CUSTOM_DTS_NAME="${SOC}-myboard"
CUSTOM_DTS_NAME="${SOC}-ev1-v6.0-mx"

MINIMAL_DEFCONFIG="0"

R0="-r0"
R1="-r1"

linux_ver="6.6.48"
devicetree_ver="6.0"

# EXTDT_DIR="${PWD}/external-dt-${devicetree_ver}${R0}/external-dt-${devicetree_ver}"
# EXTDT_DIR="${PWD}/STM32MPU-OSTL-DEV-helper/DEVICETREE/CUSTOM_EXT_DTS_FOR_DK"
EXTDT_DIR="${PWD}/STM32MPU-OSTL-DEV-helper/DEVICETREE/CUSTOM_EXT_DTS_MINIMAL_FOR_EV"

LINUX_DIR="linux-stm32mp-${linux_ver}-stm32mp${R1}${R0}"
SDK_HELPER_OUT_KERNEL="BUILD_OUTPUT/kernel/"
KERNEL_CONFIG_DIR="../../STM32MPU-OSTL-DEV-helper/TEMPLATES/STM32MP2/CONFIGS/KERNEL"
DEBUG_FILE='> kernel_config.log 2>&1'

mkdir -p ${SDK_HELPER_OUT_KERNEL}

FRAGMENT_LIST="fragment-03-systemd.config \
	       fragment-04-modules.config"

cd ${LINUX_DIR}/linux-${linux_ver}

export K_BUILD_DIR="../build/"
mkdir -p ${K_BUILD_DIR}

make O=${K_BUILD_DIR} defconfig fragment*.config ${DEBUG_FILE}

if [ "x${MINIMAL_DEFCONFIG}" = "x0" ]; then
  echo
#  for frag in ${FRAGMENT_LIST}; do
#    ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../${frag} ${DEBUG_FILE}
#  done
else
   ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config \
          ${KERNEL_CONFIG_DIR}/fragment_minimal.config >> kernel_config.log 2>&1
fi

# ./scripts/diffconfig -m  ${K_BUILD_DIR}.config ${K_BUILD_DIR}defconfig_202411292314 ${DEBUG_FILE}
# exit 0

# ./scripts/diffconfig -m ${K_BUILD_DIR}defconfig ${KERNEL_CONFIG_DIR}/minimal_defconfig > ${KERNEL_CONFIG_DIR}/fragment_minimal.config
# exit 0

# cp ${KERNEL_CONFIG_DIR}/minimal_defconfig arch/arm64/configs/stm32mp2_minimal_defconfig
# make O=${K_BUILD_DIR} stm32mp2_minimal_defconfig

# make O=${K_BUILD_DIR} menuconfig
# make O=${K_BUILD_DIR} savedefconfig
# cp -v ${K_BUILD_DIR}/defconfig  ${K_BUILD_DIR}/defconfig_`date +%Y%m%d%H%M`
# exit 0

make O=${K_BUILD_DIR} KBUILD_EXTDTS="${EXTDT_DIR}/linux" st/${CUSTOM_DTS_NAME}.dtb

make O=${K_BUILD_DIR} -j8 Image.gz
make O=${K_BUILD_DIR} -j8 modules
make O=${K_BUILD_DIR} INSTALL_MOD_PATH="../../${SDK_HELPER_OUT_KERNEL}" modules_install

cp -v ${K_BUILD_DIR}arch/arm64/boot/Image.gz                      ../../${SDK_HELPER_OUT_KERNEL}
cp -v ${K_BUILD_DIR}arch/arm64/boot/dts/st/${CUSTOM_DTS_NAME}.dtb ../../${SDK_HELPER_OUT_KERNEL}
rm ../../${SDK_HELPER_OUT_KERNEL}/lib/modules/6.6.48/build
