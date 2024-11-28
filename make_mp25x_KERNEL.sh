#!/bin/bash -e

export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games
export ARCH=arm64
SDK_BUILD_ENV_PATH="/opt/st/stm32mp2/5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06/environment-setup-cortexa35-ostl-linux"
source ${SDK_BUILD_ENV_PATH}

SOC_BASE="stm32mp25"
SOC="${SOC_BASE}7f"
# CUSTOM_DTS_NAME="${SOC}-ev1"
CUSTOM_DTS_NAME="${SOC}-dk"

MINIMAL_DEFCONFIG="0"

R0="-r0"
R1="-r1"

linux_ver="6.6.48"
devicetree_ver="6.0"

EXTDT_DIR=${PWD}/external-dt-${devicetree_ver}${R0}/external-dt-${devicetree_ver}
LINUX_DIR="linux-stm32mp-${linux_ver}-stm32mp${R1}${R0}"
SDK_HELPER_OUT_KERNEL="BUILD_OUTPUT/kernel/"
mkdir -p ${SDK_HELPER_OUT_KERNEL}

# echo ${EXTDT_DIR}
# echo ${LINUX_DIR}
# exit 0

FRAGMENT_LIST="fragment-03-systemd.config \
	       fragment-04-modules.config"

cd ${LINUX_DIR}/linux-${linux_ver}

export K_BUILD_DIR="../build/"
mkdir -p ${K_BUILD_DIR}


if [ "x${MINIMAL_DEFCONFIG}" = "x0" ]; then
  make O=${K_BUILD_DIR} defconfig fragment*.config
  for frag in ${FRAGMENT_LIST}; do
    ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../${frag}
  done
else
   make O=${K_BUILD_DIR} defconfig 
   ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../../STM32MPU_SDK_helper/KERNEL/fragment_minimal.config
fi

# ./scripts/diffconfig -m ${K_BUILD_DIR}defconfig ../../STM32MPU_SDK_helper/KERNEL/minimal_defconfig > ../../STM32MPU_SDK_helper/KERNEL/fragment_minimal.config
# exit 0

# cp ../../STM32MPU_SDK_helper/KERNEL/minimal_defconfig arch/arm64/configs/stm32mp2_minimal_defconfig
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
