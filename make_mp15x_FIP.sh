#!/bin/bash -e
# (-ex is verbose)
##############################################################################################################
##############################################################################################################
###                                                                                                        ###
###  Please customize the following VARIABLEs:                                                             ###
###                                             SOC=                                                       ###
###                                             CUSTOM_DTS_NAME=                                           ###
###						SOURCES_BASE_PATH=                                         ###
###                                             SDK_BUILD_ENV_BASE=                                        ###
###                                                                                                        ###
##############################################################################################################
##############################################################################################################

#####################################################
###                                          ########
###    OPTIONAL CUSTOM CONFIGURATION         ########
###                                          ########
#####################################################

###########################################################################
# Build FIP and TF-A for this BOOT_DEVICE 
# available BOOT_DEVICE: "emmc" "sdcard" "nor"
BOOT_DEVICE="sdcard"

###########################################################################
# OPTEE version: standard or min
# Available options: "optee" - "opteemin"
# OPTEE_TYPE="opteemin"
OPTEE_TYPE="optee"

###########################################################################
# Programming channel
# Available options: "usb" - "uart"
PRG_BUS="usb"

### CUSTOM u-boot configs file ######################
# CUSTOM_UBOOT_DEFCONFIG="STM32MPU-OSTL-DEV-helper/STM32MPU-OSTL-DEV-helper/TEMPLATES/STM32MP2/CONFIGS/stm32mp25_defconfig_u-boot"

##############################################################################################################
###                                                                                                 ##########
###          MANDATORY DEFINITIONs                                                                  ##########
###                                                                                                 ##########
##############################################################################################################

STM32MP_PLATFORM="stm32mp1"
SOC_BASE="stm32mp15"
SOC="${SOC_BASE}7c"

### DTS name (external dts, can be a custom name) ###
## ST board DTS names
# CUSTOM_DTS_NAME="${SOC}-ev1"
CUSTOM_DTS_NAME="${SOC}-dk2"

# CUSTOM_DTS_NAME="${SOC}-myboard"

SOURCES_BASE_PATH="./"
SDK_BUILD_ENV_BASE="/opt/st/${STM32MP_PLATFORM}/5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06"

##############################################################################################################
###                                                                                                 ##########
###          OPTIONAL SETTINGs                                                                      ##########
###                                                                                                 ##########
##############################################################################################################

BUILD_TFA="1"    # Build tfa + FIP
BUILD_OPTEE="1"  # Build optee + FIP
BUILD_UBOOT="1"  # Build uboot + FIP

DO_CLEAN="1"     # Clean up the build folder & FIP_artifacts folder before build.
DO_CLEAN_DTB="1" # Clean up all DTBs before build.
DO_CLEAN_ALL="0" # Clean up FIP_artifacts folder.

BUILD_HELPER_OUTPUT="1" # Copy final artifact in OUT folder and create tar.gz archive (under ./BUILD_OUTPUT) 

##############################################################################################################
###                                                                                                 ##########
###          SYSTEM ENVIRONMENT                                                                     ##########
###                                                                                                 ##########
##############################################################################################################

SDK_BUILD_ENV_PATH="${SDK_BUILD_ENV_BASE}/environment-setup-cortexa7t2hf-neon-vfpv4-ostl-linux-gnueabi"

for component in optee-os tf-a u-boot; do
    [[ "x`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* 2>/dev/null`" == "x" ]] && continue

       component_ver=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\1/g"`
    component_ver_Ra=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\2/g"`
    component_ver_Rb=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\3/g"`

    case ${component} in
	"tf-a")
	  	tfa_ver_Rb=${component_ver_Rb}
		TFA_DIR="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}-r${component_ver_Rb}/${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
	"optee-os")
	  	optee_ver_Rb=${component_ver_Rb}
		OPTEE_DIR="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}-r${component_ver_Rb}/${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
	"u-boot")
	  	uboot_ver_Rb=${component_ver_Rb}
		UBOOT_DIR="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}-r${component_ver_Rb}/${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
    esac
done

NUM_COREs=4

cd ${SOURCES_BASE_PATH}
CURDIR=`pwd`

SDK_HELPER_OUTPUT="BUILD_OUTPUT"
SDK_HELPER_OUTPUT_FIP="${SDK_HELPER_OUTPUT}/fip"
SDK_HELPER_OUTPUT_TFA="${SDK_HELPER_OUTPUT}/tfa"

FIP_DEPLOYDIR_ROOT="${CURDIR}/FIP_artifacts"

##############################################################################################################
##############################################################################################################
###                                                                                                 ##########
###          START OF OPERATIONs                                                                    ##########
###                                                                                                 ##########
##############################################################################################################
##############################################################################################################

if [[ "x${DO_CLEAN_ALL}" = "x1" ]]; then
  DO_CLEAN="1"
  rm -rf ${FIP_DEPLOYDIR_ROOT}
fi

FIP_CONFIGs="${OPTEE_TYPE}-${BOOT_DEVICE} ${OPTEE_TYPE}-programmer-${PRG_BUS}"

# Toolchain setup
source ${SDK_BUILD_ENV_PATH}

function do_build_uboot() {

  export EXTDT_DIR
  rm -rf   ${FIP_DEPLOYDIR_ROOT}/u-boot ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin
  mkdir -p ${FIP_DEPLOYDIR_ROOT}/u-boot
  
  cd ${UBOOT_DIR}

  UBOOT_DEFCONFIG="${SOC_BASE}_defconfig"
  if [ ! -z "${CUSTOM_UBOOT_DEFCONFIG}" ]; then
     if [ -f "../../${CUSTOM_UBOOT_DEFCONFIG}" ]; then
        cp -v ../../${CUSTOM_UBOOT_DEFCONFIG} configs/${SOC_BASE}_custom_defconfig
        UBOOT_DEFCONFIG="${SOC_BASE}_custom_defconfig"
     fi
  fi
  
  [[     "x${DO_CLEAN}" = "x1" ]] && make -f ../Makefile.sdk UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/u-boot clean
  [[     "x${DO_CLEAN}" = "x1" ]] && rm -rf ../deploy
  [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -f ../build/${UBOOT_DEFCONFIG}/arch/arm/dts/.${SOC_BASE}* \
					   ../build/${UBOOT_DEFCONFIG}/arch/arm/dts/*dtb
  [[ "x${DO_NOT_BUILD}" = "x1" ]] && cd - && return 0
  
  for dt in ${CUSTOM_DTS_NAME}; do
     make -f ../Makefile.sdk UBOOT_CONFIG=${BOOT_DEVICE} DEVICETREE=${dt} DEVICE_TREE=${dt} UBOOT_DEVICETREE_stm32mp15_defconfig=${dt} \
			     UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} UBOOT_BINARY=u-boot.dtb \
			     DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/u-boot uboot
  done

  cd -
}

function do_build_optee() {
  
  rm -rf   ${FIP_DEPLOYDIR_ROOT}/optee ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin
  mkdir -p ${FIP_DEPLOYDIR_ROOT}/optee

  cd ${OPTEE_DIR}

  [[ "x${DO_CLEAN}" = "x1" ]] && make -f ../Makefile.sdk CFG_EMBED_DTB_SOURCE_FILE=${CUSTOM_DTS_NAME} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/optee clean
  [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -f ../build/${CUSTOM_DTS_NAME}/core/arch/arm/dts/.${STM32MP_PLATFORM}* out/arm-plat-${STM32MP_PLATFORM}/core/arch/arm/dts/${STM32MP_PLATFORM}*
  [[ "x${DO_NOT_BUILD}" = "x1" ]] && cd - && return 0

  OPTEE_EXTRA_OEMAKE_OPTs="-j${NUM_COREs} PLATFORM=${STM32MP_PLATFORM} CROSS_COMPILE_core=arm-ostl-linux-gnueabi- \
			  CROSS_COMPILE_ta_arm64=arm-ostl-linux-gnueabi- ARCH=arm CFG_ARM32_core=y NOWERROR=1 \
			  CROSS_COMPILE_ta_arm32=arm-ostl-linux-gnueabi- LDFLAGS= CFG_TEE_CORE_LOG_LEVEL=2 \
			  CFG_TEE_CORE_DEBUG=n CFG_${STM32MP_PLATFORM}5=y CFG_STM32MP_PROFILE=system_services"
 
  make -f ../Makefile.sdk CFG_EMBED_DTB_SOURCE_FILE=${CUSTOM_DTS_NAME} OPTEE_CONFIG=${OPTEE_TYPE} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/optee EXTRA_OEMAKE="${OPTEE_EXTRA_OEMAKE_OPTs}" optee

  cd -
}

function do_build_tfa() {
  
  rm -rf   ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin

  cd ${TFA_DIR}
 
  TFA_COMMON_OPTs="ELF_DEBUG_ENABLE=1 DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware"
  TFA_EXTRA_OEMAKE_OPTs="-j${NUM_COREs} PLAT=${STM32MP_PLATFORM} ARCH=aarch32 ARM_ARCH_MAJOR=7 CROSS_COMPILE=arm-ostl-linux-gnueabi- \
			DEBUG=0 LOG_LEVEL=40 AARCH32_SP=optee"

  for tfa_target in ${FIP_CONFIGs}; do
   
     if [[ "x${tfa_target}" == "xusb" ]]; then
        TGT_OPTs="STM32MP_USB_PROGRAMMER=1"
     elif [[ "x${tfa_target}" == "xsdcard" ]]; then
        TGT_OPTs="PSA_FWU_SUPPORT=1 STM32MP_SDMMC=1"
     elif [[ "x${tfa_target}" == "xemmc" ]]; then
        TGT_OPTs="PSA_FWU_SUPPORT=1 STM32MP_EMMC=1"
     fi
     TFA_SPECIFIC_OPTs="TF_A_CONFIG=${tfa_target} TF_A_DEVICETREE=${CUSTOM_DTS_NAME} ${TGT_OPTs}"
     
     [[ "x${DO_CLEAN}" = "x1" ]] && make -f ../Makefile.sdk ${TFA_SPECIFIC_OPTs} clean
     [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -fr ../build/${tfa_target}${CUSTOM_DTS_NAME}/fdts
       
     # Build stm32 binary (foreach TF_A_CONFIG)
     make -f ../Makefile.sdk ${TFA_COMMON_OPTs} ${TFA_SPECIFIC_OPTs} EXTRA_OEMAKE="${TFA_EXTRA_OEMAKE_OPTs}" stm32
  done
  
  make -f ../Makefile.sdk DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware metadata

  cd -
}


function do_build_fip() {
  
  cd ${UBOOT_DIR}
  
#  for storage in programmer-${PRG_BUS} ${BOOT_DEVICE}; do
  for storage in ${BOOT_DEVICE}; do
    device="${OPTEE_TYPE}-${storage}"

     make -f ../Makefile.sdk UBOOT_CONFIG=${device} FIP_CONFIG=${device} UBOOT_BINARY=u-boot.dtb \
			     FIP_DEPLOYDIR_ROOT=${FIP_DEPLOYDIR_ROOT} DEVICE_TREE=${CUSTOM_DTS_NAME} \
			     DEVICETREE=${CUSTOM_DTS_NAME} UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} fip
  done  

  cd -
}

[[ "x${BUILD_UBOOT}" == "x1" ]] && do_build_uboot
[[ "x${BUILD_OPTEE}" == "x1" ]] && do_build_optee
[[   "x${BUILD_TFA}" == "x1" ]] && do_build_tfa 

do_build_fip # Assemble FIP file

echo; echo; echo

[[ "x${BUILD_HELPER_OUTPUT}" != "x1" ]] && exit 0

mkdir -p ${SDK_HELPER_OUTPUT_FIP}
mkdir -p ${SDK_HELPER_OUTPUT_TFA}

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/metadata.bin 	 ${SDK_HELPER_OUTPUT_TFA}/metadata.bin

SRC_FILENAME="${CUSTOM_DTS_NAME}-${OPTEE_TYPE}-${BOOT_DEVICE}"
DST_FILENAME="${BOOT_DEVICE}"

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/tf-a-${SRC_FILENAME}.stm32 \
      ${SDK_HELPER_OUTPUT_TFA}/tfa_${DST_FILENAME}.stm32
cp -v ${FIP_DEPLOYDIR_ROOT}/fip/fip-${SRC_FILENAME}.bin     ${SDK_HELPER_OUTPUT_FIP}/fip.bin

PRG_SRC_FILENAME="${CUSTOM_DTS_NAME}-${OPTEE_TYPE}-programmer-${PRG_BUS}"
PRG_DST_FILENAME="${PRG_BUS}"

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/tf-a-${PRG_SRC_FILENAME}.stm32 \
      ${SDK_HELPER_OUTPUT_TFA}/tfa_${PRG_DST_FILENAME}.stm32
cp -v ${FIP_DEPLOYDIR_ROOT}/fip/fip-${SRC_FILENAME}.bin ${SDK_HELPER_OUTPUT_FIP}/fip_${PRG_DST_FILENAME}.bin

cp -rv STM32MPU-OSTL-DEV-helper/FLASH_LAYOUT   ${SDK_HELPER_OUTPUT}/
mv ${SDK_HELPER_OUTPUT}/FLASH_LAYOUT/flash.sh  ${SDK_HELPER_OUTPUT}/
chmod 755 ${SDK_HELPER_OUTPUT}/flash.sh
mv ${SDK_HELPER_OUTPUT}/FLASH_LAYOUT/flash.bat ${SDK_HELPER_OUTPUT}/


tar czf /tmp/${CUSTOM_DTS_NAME}_binaries.tar.gz  ${SDK_HELPER_OUTPUT}
echo; echo
ls -lh /tmp/${CUSTOM_DTS_NAME}_binaries.tar.gz 

echo; echo; echo
exit 0
