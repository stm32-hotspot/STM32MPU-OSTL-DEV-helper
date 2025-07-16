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


# EXTDT_WORKING_DIR="${PWD}/${EXTERNAL_DT_DIR}"
# EXTDT_WORKING_DIR="${PWD}/STM32MPU-OSTL-DEV-helper/DEVICETREE/CUSTOM_EXT_DTS_FOR_DK"
EXTDT_WORKING_DIR="${PWD}/STM32MPU-OSTL-DEV-helper/DEVICETREE/CUSTOM_EXT_DTS_MINIMAL_FOR_EV"

SDK_HELPER_OUT_KERNEL="BUILD_OUTPUT/kernel/"

KERNEL_CONFIG_DIR="../../STM32MPU-OSTL-DEV-helper/TEMPLATES/STM32MP2/CONFIGS/KERNEL"
DEBUG_FILE='> kernel_config.log 2>&1'

if [ ! -f "/tmp/FIP_SCRIPT_done.txt" ]; then
   echo ""
   echo ""
   echo "  ##################################################################"
   echo "  ##"
   echo "  ##  Please run make_mp<XX>_FIP.sh script"
   echo "  ##  before running $0 script."
   echo "  ##"
   echo "  ##################################################################"
   echo ""
   echo ""
   exit 0
fi

for component in linux external-dt; do
    if [ "x`ls -1d ${component}-* 2>/dev/null | grep -v stm32mp`" != "x" ]; then
          component_ver=`ls -1d ${component}-*-r* | sed -e "s/${component}-\(.*\)-r\(.*\)/\1/g"`
       component_ver_Ra=`ls -1d ${component}-*-r* | sed -e "s/${component}-\(.*\)-r\(.*\)/\2/g"`
       component_ver_Rb=""
       EXTERNAL_DT_DIR="${component}-${component_ver}-r${component_ver_Ra}/${component}-${component_ver}"
    fi

    [[ "x`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* 2>/dev/null`" == "x" ]] && continue

       component_ver=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\1/g"`
    component_ver_Ra=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\2/g"`
    component_ver_Rb=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\3/g"`

    case ${component} in
	"linux")
	  	tfa_ver_Rb=${component_ver_Rb}
		LINUX_DIR="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}-r${component_ver_Rb}/${component}-${component_ver}"
		;;
    esac
done

mkdir -p ${SDK_HELPER_OUT_KERNEL}

FRAGMENT_LIST="fragment-03-systemd.config \
	       fragment-04-modules.config"

cd ${LINUX_DIR}

export K_BUILD_DIR="../build/"
mkdir -p ${K_BUILD_DIR}

make O=${K_BUILD_DIR} defconfig fragment*.config ${DEBUG_FILE}
# make O=${K_BUILD_DIR} defconfig 

if [ "x${MINIMAL_DEFCONFIG}" = "x0" ]; then
  echo
  for frag in ${FRAGMENT_LIST}; do
    ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config ../${frag}
  done
else
   ./scripts/kconfig/merge_config.sh -m -r -O ${K_BUILD_DIR} ${K_BUILD_DIR}/.config \
          ${KERNEL_CONFIG_DIR}/fragment_minimal.config >> kernel_config.log 2>&1
fi

(yes '' || true) | make O=${K_BUILD_DIR} oldconfig

# ./scripts/diffconfig -m  ${K_BUILD_DIR}.config ${K_BUILD_DIR}defconfig_202411292314 ${DEBUG_FILE}
# exit 0

## Uncomment below line to generate a new kernel fragment file
# ./scripts/diffconfig -m ${K_BUILD_DIR}defconfig ${KERNEL_CONFIG_DIR}/old_defconfig > ${KERNEL_CONFIG_DIR}/fragment_minimal.config
# exit 0

## Uncomment below line if you want to use minimal_defconfig file for kernel configuration
# cp ${KERNEL_CONFIG_DIR}/minimal_defconfig arch/arm64/configs/stm32mp2_minimal_defconfig
# make O=${K_BUILD_DIR} stm32mp2_minimal_defconfig

# make O=${K_BUILD_DIR} menuconfig
# make O=${K_BUILD_DIR} savedefconfig
# cp -v ${K_BUILD_DIR}/defconfig  ${K_BUILD_DIR}/defconfig_`date +%Y%m%d%H%M`
# exit 0

make O=${K_BUILD_DIR} KBUILD_EXTDTS="${EXTDT_WORKING_DIR}/linux" st/${CUSTOM_DTS_NAME}.dtb

make O=${K_BUILD_DIR} -j8 Image.gz
make O=${K_BUILD_DIR} -j8 modules
make O=${K_BUILD_DIR} INSTALL_MOD_PATH="../../${SDK_HELPER_OUT_KERNEL}" modules_install

cp -v ${K_BUILD_DIR}arch/arm64/boot/Image.gz                      ../../${SDK_HELPER_OUT_KERNEL}
cp -v ${K_BUILD_DIR}arch/arm64/boot/dts/st/${CUSTOM_DTS_NAME}.dtb ../../${SDK_HELPER_OUT_KERNEL}
rm -f ../../${SDK_HELPER_OUT_KERNEL}/lib/modules/6.6.48/build
