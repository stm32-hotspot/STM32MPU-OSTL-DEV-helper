#!/bin/bash -e

NEW_NAME="my-new-prj-name"

### DEVICETREE FOLDER generated by CubeMX:                    ###
CUBEMX_PRJ_DIR="STM32MPU-OSTL-DEV-helper/DEVICETREE/STM32MP25x_CubeMX/CA35/DeviceTree/"

### CubeMX Project name:                                      ###
CUBEMX_PRJ_NAME="ev1-v6.0" # <- This definition overrides CUSTOM_DTS_NAME value!!

startstr="stm32mp257f-"
midstr="-mx"

cd ${CUBEMX_PRJ_DIR}
mv -v ${CUBEMX_PRJ_NAME} ${NEW_NAME}

sed -e s/${CUBEMX_PRJ_NAME}/${NEW_NAME}/g ../../${CUBEMX_PRJ_NAME}.ioc > ../../${NEW_NAME}.ioc
rm ../../${CUBEMX_PRJ_NAME}.ioc

sed -e s/${CUBEMX_PRJ_NAME}/${NEW_NAME}/g ../../.project > project_tmp
mv project_tmp ../../.project

cd ${NEW_NAME}

for n in kernel optee-os tf-a u-boot; do
   cd ${n}
   case ${n} in
	"tf-a")     endstrs="-rcc.dtsi -fw-config.dts -usercodes.dtsi"; mkfile="" ;;
	"optee-os") endstrs="-rcc.dtsi -rif.dtsi -resmem.dtsi -usercodes.dtsi"; mkfile="conf.mk" ;;
	"u-boot")   endstrs="-resmem.dtsi -usercodes.dtsi -u-boot.dtsi -u-boot-usercodes.dtsi"; mkfile="Makefile" ;;
	"kernel")   endstrs="-resmem.dtsi -usercodes.dtsi"; mkfile="Makefile" ;;
   esac

   [[ ! -z "${mkfile}" ]] && sed -e s/${CUBEMX_PRJ_NAME}/${NEW_NAME}/g ${mkfile} > ${mkfile}_tmp && mv ${mkfile}_tmp ${mkfile}

   sed -e s/${CUBEMX_PRJ_NAME}/${NEW_NAME}/g ${startstr}${CUBEMX_PRJ_NAME}${midstr}.dts > ${startstr}${NEW_NAME}${midstr}.dts
   rm ${startstr}${CUBEMX_PRJ_NAME}${midstr}.dts

   for endstr in ${endstrs}; do
     sed -e s/${CUBEMX_PRJ_NAME}/${NEW_NAME}/g ${startstr}${CUBEMX_PRJ_NAME}${midstr}${endstr} > ${startstr}${NEW_NAME}${midstr}${endstr}
     rm ${startstr}${CUBEMX_PRJ_NAME}${midstr}${endstr}
   done
   cd - > /dev/null
done