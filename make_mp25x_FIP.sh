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
### EXTERNAL DEVICETREE. If defined a customized EXTERNAL DEVICE TREE folder will be used  ###
# CUSTOM_EXTDT_DIR="STM32MPU-OSTL-DEV-helper/CUSTOM_EXT_DTS"
### CUSTOM u-boot configs file ######################
# CUSTOM_UBOOT_DEFCONFIG="STM32MPU-OSTL-DEV-helper/UBOOT/stm32mp25_defconfig_u-boot"

##############################################################################################################
###                                                                                                 ##########
###          MANDATORY DEFINITIONs                                                                  ##########
###                                                                                                 ##########
##############################################################################################################

SOC_BASE="stm32mp25"
SOC="${SOC_BASE}7f"

### DTS name (external dts, can be a custom name) ###
STD_DT="${SOC}-dk" # Do not change this default value, please.
## ST board DTS names
# CUSTOM_DTS_NAME="${SOC}-ev1" # Eval board
# CUSTOM_DTS_NAME="${SOC}-dk"  # Disco board
## External DTS example name
# CUSTOM_DTS_NAME="${SOC}-ev1-ca35tdcid-ostl" Disco board with core A35 Trusted Domain

# CUSTOM_DTS_NAME="${SOC}-myboard" # Associate this with CUSTOM_EXTDT_DIR
CUSTOM_DTS_NAME="${SOC}-dk"

###########################################################################
# Build FIP and TF-A for this BOOT_DEVICE 
# available BOOT_DEVICE: "emmc" "sdcard" "nor"
BOOT_DEVICE="emmc"

###########################################################################
# OPTEE version: standard or min
# Available options: "optee" - "opteemin"
# OPTEE_TYPE="opteemin"
OPTEE_TYPE="optee"

###########################################################################
# Programming channel
# Available options: "usb" - "uart"
PRG_BUS="usb"

SOURCES_BASE_PATH="./"
SDK_BUILD_ENV_BASE="/opt/st/stm32mp2/5.0.3-openstlinux-6.6-yocto-scarthgap-mpu-v24.11.06"

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
DO_CLEAN_ALL="1" # Clean up FIP_artifacts folder.

BUILD_HELPER_OUTPUT="1" # Copy final artifact in OUT folder and create tar.gz archive (under ./BUILD_OUTPUT) 

##############################################################################################################
###                                                                                                 ##########
###          SYSTEM ENVIRONMENT                                                                     ##########
###                                                                                                 ##########
##############################################################################################################

SDK_BUILD_ENV_PATH="${SDK_BUILD_ENV_BASE}/environment-setup-cortexa35-ostl-linux"

R0="-r0"
R1="-r1"
R2="-r2"
RC8="-rc8"

optee_ver="4.0.0"
tfa_ver="v2.10.5"
ddr_ver="A2022.11"
uboot_ver="v2023.10"
devicetree_ver="6.0"

TFA_VER="${tfa_ver}-stm32mp${R1}"
UBOOT_VER="${uboot_ver}-stm32mp${R1}"
OPTEE_VER="${optee_ver}-stm32mp${R1}"
DDR_VER="${ddr_ver}"
DEVICETREE_VER="${devicetree_ver}"

TFA_DIR="tf-a-stm32mp-${TFA_VER}${R0}/tf-a-stm32mp-${TFA_VER}"
UBOOT_DIR="u-boot-stm32mp-${UBOOT_VER}${R0}/u-boot-stm32mp-${UBOOT_VER}"
OPTEE_DIR="optee-os-stm32mp-${OPTEE_VER}${R0}/optee-os-stm32mp-${OPTEE_VER}"
NUM_COREs=8

cd ${SOURCES_BASE_PATH}
CURDIR=`pwd`

if [ -z "${CUSTOM_EXTDT_DIR}" ]; then
   EXTDT_DIR="${CURDIR}/external-dt-${DEVICETREE_VER}${R0}/external-dt-${DEVICETREE_VER}"
 else
   for d in tf-a optee u-boot; do
     [[ ! -d "${CUSTOM_EXTDT_DIR}/${d}" ]] && echo -e "\n\tError: folder ${CUSTOM_EXTDT_DIR}/${d} does not exist, please correct the path\n\n" && exit 0
   done
   EXTDT_DIR="${CURDIR}/${CUSTOM_EXTDT_DIR}"
fi

FWDDR_DIR="${CURDIR}/stm32mp-ddr-phy-${DDR_VER}${R0}/stm32mp-ddr-phy-${DDR_VER}"

SDK_HELPER_OUTPUT="BUILD_OUTPUT"
SDK_HELPER_OUTPUT_FIP="${SDK_HELPER_OUTPUT}/fip"
SDK_HELPER_OUTPUT_TFA="${SDK_HELPER_OUTPUT}/tfa"

FIP_DEPLOYDIR_ROOT="${CURDIR}/FIP_artifacts"

# echo ${TFA_DIR}
# echo ${OPTEE_DIR}
# echo ${UBOOT_DIR}
# echo ${EXTDT_DIR}
# echo ${FWDDR_DIR}
# exit 0

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

for storage in ${BOOT_DEVICE}; do
    FIP_CONFIGs="${FIP_CONFIGs} ${OPTEE_TYPE}-${storage}"
done
FIP_CONFIGs="${FIP_CONFIGs} ${OPTEE_TYPE}-programmer-${PRG_BUS}"

# Toolchain setup
source ${SDK_BUILD_ENV_PATH}
export EXTDT_DIR
export FWDDR_DIR

function do_build_uboot() {

  export EXTDT_DIR
  rm -rf   ${FI25DEPLOYDIR_ROOT}/u-boot ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin
  mkdir -p ${FIP_DEPLOYDIR_ROOT}/u-boot
  
  cd ${UBOOT_DIR}

  UBOOT_DEFCONFIG="${SOC_BASE}_defconfig"
  if [ ! -z "${CUSTOM_UBOOT_DEFCONFIG}" ]; then
     if [ -f "../../${CUSTOM_UBOOT_DEFCONFIG}" ]; then
        cp -v ../../${CUSTOM_UBOOT_DEFCONFIG} configs/${SOC_BASE}_custom_defconfig
        UBOOT_DEFCONFIG="${SOC_BASE}_custom_defconfig"
     fi
  fi
  
  [[ "x${DO_CLEAN}" = "x1" ]] &&  make -f ../Makefile.sdk UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} DEVICE_TREE=${CUSTOM_DTS_NAME} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/u-boot clean
  [[ "x${DO_CLEAN}" = "x1" ]] &&  rm -rf ../deploy
  [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -f ../build/${UBOOT_DEFCONFIG}/arch/arm/dts/.${SOC_BASE}* \
					   ../build/${UBOOT_DEFCONFIG}/arch/arm/dts/*dtb \
					   ${EXTDT_DIR}/u-boot/*dtb ${EXTDT_DIR}/u-boot/.${SOC_BASE}*
  [[ "x${DO_NOT_BUILD}" = "x1" ]] && cd - && return 0
  
  for dt in ${STD_DT} ${CUSTOM_DTS_NAME}; do
     make -f ../Makefile.sdk UBOOT_CONFIG=${BOOT_DEVICE} DEVICE_TREE=${dt} \
			     UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} UBOOT_BINARY=u-boot.dtb \
			     DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/u-boot uboot
  done

  cd -
}

function do_build_optee() {
  
  export EXTDT_DIR
  rm -rf   ${FIP_DEPLOYDIR_ROOT}/optee ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin
  mkdir -p ${FIP_DEPLOYDIR_ROOT}/optee

  cd ${OPTEE_DIR}

  [[ "x${DO_CLEAN}" = "x1" ]] && make -f ../Makefile.sdk CFG_EMBED_DTB_SOURCE_FILE=${CUSTOM_DTS_NAME} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/optee clean
  [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -f ../build/${CUSTOM_DTS_NAME}/core/arch/arm/dts/.stm32mp2* out/arm-plat-stm32mp2/core/arch/arm/dts/stm32mp2*
  [[ "x${DO_NOT_BUILD}" = "x1" ]] && cd - && return 0

  OPTEE_EXTRA_OEMAKE_OPTs="-j${NUM_COREs} PLATFORM=stm32mp2 CROSS_COMPILE_core=aarch64-ostl-linux- \
			  CROSS_COMPILE_ta_arm64=aarch64-ostl-linux- ARCH=arm CFG_ARM64_core=y NOWERROR=1 \
			  LDFLAGS= CFG_EXT_DTS=${EXTDT_DIR}/optee CFG_TEE_CORE_LOG_LEVEL=2 \
			  CFG_TEE_CORE_DEBUG=y CFG_SCMI_SCPFW=y"
 
  make -f ../Makefile.sdk CFG_EMBED_DTB_SOURCE_FILE=${CUSTOM_DTS_NAME} DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/optee OPTEE_CONFIG=${OPTEE_TYPE} EXTRA_OEMAKE="${OPTEE_EXTRA_OEMAKE_OPTs}" optee

  cd -
}

function do_build_tfa() {
  
  export EXTDT_DIR
  export FWDDR_DIR
  rm -rf   ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware ${FIP_DEPLOYDIR_ROOT}/fip-${CUSTOM_DTS_NAME}-*.bin

  cd ${TFA_DIR}
 
  TFA_COMMON_OPTs="ELF_DEBUG_ENABLE=1 DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware"
  TFA_EXTRA_OEMAKE_OPTs="-j${NUM_COREs} PLAT=stm32mp2 ARCH=aarch64 ARM_ARCH_MAJOR=8 CROSS_COMPILE=aarch64-ostl-linux- \
			DEBUG=0 LOG_LEVEL=40 TFA_EXTERNAL_DT=${EXTDT_DIR}/tf-a"

  for tfa_target in ${FIP_CONFIGs}; do
   
     TFA_SPECIFIC_OPTs="TF_A_CONFIG=${tfa_target} TF_A_DEVICETREE=${CUSTOM_DTS_NAME} TF_A_ENABLE_FWDDR=1"
     
     [[ "x${DO_CLEAN}" = "x1" ]] && make -f ../Makefile.sdk ${TFA_SPECIFIC_OPTs} clean
     [[ "x${DO_CLEAN_DTB}" = "x1" ]] && rm -fr ../build/${tfa_target}${CUSTOM_DTS_NAME}/fdts
       
     # Build stm32 binary (foreach TF_A_CONFIG)
     make -f ../Makefile.sdk ${TFA_COMMON_OPTs} ${TFA_SPECIFIC_OPTs} EXTRA_OEMAKE="${TFA_EXTRA_OEMAKE_OPTs}" stm32
  done
  
  make -f ../Makefile.sdk metadata DEPLOYDIR=${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware

  cd -
}


function do_build_fip() {
  
  export EXTDT_DIR
  export FWDDR_DIR
  cd ${UBOOT_DIR}
  
  for storage in programmer-${PRG_BUS} ${BOOT_DEVICE}; do
    device="${OPTEE_TYPE}-${storage}"

     make -f ../Makefile.sdk UBOOT_CONFIG=${device} FIP_CONFIG=${device} UBOOT_BINARY=u-boot.dtb \
			     FIP_DEPLOYDIR_ROOT=${FIP_DEPLOYDIR_ROOT} DEVICE_TREE=${CUSTOM_DTS_NAME} \
			     UBOOT_DEFCONFIG=${UBOOT_DEFCONFIG} fip
  done  

  cd -
}

[[ "x${BUILD_UBOOT}" = "x1" ]] && do_build_uboot
[[ "x${BUILD_OPTEE}" = "x1" ]] && do_build_optee
[[ "x${BUILD_TFA}" = "x1" ]] && do_build_tfa 
do_build_fip # Assemble FIP file

echo; echo; echo

[[ "x${BUILD_HELPER_OUTPUT}" != "x1" ]] && exit 0

mkdir -p ${SDK_HELPER_OUTPUT_FIP}
mkdir -p ${SDK_HELPER_OUTPUT_TFA}

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/metadata.bin 	 ${SDK_HELPER_OUTPUT_TFA}/metadata.bin

SRC_FILENAME="${CUSTOM_DTS_NAME}-${OPTEE_TYPE}-${BOOT_DEVICE}"
SRC_FILENAME_DDR="${CUSTOM_DTS_NAME}-ddr-${OPTEE_TYPE}-${BOOT_DEVICE}"
DST_FILENAME="${BOOT_DEVICE}"

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/tf-a-${SRC_FILENAME}.stm32 \
      ${SDK_HELPER_OUTPUT_TFA}/tfa_${DST_FILENAME}.stm32
cp -v ${FIP_DEPLOYDIR_ROOT}/fip/fip-${SRC_FILENAME}.bin     ${SDK_HELPER_OUTPUT_FIP}/fip.bin
cp -v ${FIP_DEPLOYDIR_ROOT}/fip/fip-${SRC_FILENAME_DDR}.bin ${SDK_HELPER_OUTPUT_FIP}/fip-ddr.bin

PRG_SRC_FILENAME="${CUSTOM_DTS_NAME}-${OPTEE_TYPE}-programmer-${PRG_BUS}"
PRG_DST_FILENAME="${PRG_BUS}"

cp -v ${FIP_DEPLOYDIR_ROOT}/arm-trusted-firmware/tf-a-${PRG_SRC_FILENAME}.stm32 \
      ${SDK_HELPER_OUTPUT_TFA}/tfa_${PRG_DST_FILENAME}.stm32
cp -v ${FIP_DEPLOYDIR_ROOT}/fip/fip-${PRG_SRC_FILENAME}.bin ${SDK_HELPER_OUTPUT_FIP}/fip_${PRG_DST_FILENAME}.bin

cp -rv STM32MPU-OSTL-DEV-helper/FLASH_LAYOUT   ${SDK_HELPER_OUTPUT}/
mv ${SDK_HELPER_OUTPUT}/FLASH_LAYOUT/flash.sh  ${SDK_HELPER_OUTPUT}/
mv ${SDK_HELPER_OUTPUT}/FLASH_LAYOUT/flash.bat ${SDK_HELPER_OUTPUT}/


tar czf /tmp/${CUSTOM_DTS_NAME}_binaries.tar.gz  ${SDK_HELPER_OUTPUT}
echo; echo
ls -lh /tmp/${CUSTOM_DTS_NAME}_binaries.tar.gz 

echo; echo; echo
exit 0
