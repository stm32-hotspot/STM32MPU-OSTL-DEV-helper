#!/bin/bash -e


for component in external-dt stm32mp-ddr-phy; do
    [[ "x`ls -1d ${component}-* 2>/dev/null`" == "x" ]] && continue
    component_ver=`ls -1d ${component}-* | sed -e "s/${component}-\(.*\)-r\(.*\)/\1/g"`
    component_ver_Rb=`ls -1d ${component}-*-r* | sed -e "s/${component}-\(.*\)-r\(.*\)/\2/g"`

    case ${component} in
	"external-dt")
	  	devicetree_ver_Rb=${component_ver_Rb}
		devicetree_dir="${component}-${component_ver}"
		;;
	"stm32mp-ddr-phy")
	  	ddrphy_ver_Rb=${component_ver_Rb}
		ddrphy_dir="${component}-${component_ver}"
		;;
    esac
done

for component in gcnano-driver linux optee-os tf-a u-boot; do
    [[ "x`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* 2>/dev/null`" == "x" ]] && continue

       component_ver=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\1/g"`
    component_ver_Ra=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\2/g"`
    component_ver_Rb=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp-r\(.*\)-r\(.*\)/\3/g"`

    case ${component} in
	"gcnano-driver")
		   gcnano_ver=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp\(.*\)-r\(.*\)-r\(.*\)/\1/g"`
  		    gcnano_mp=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp\(.*\)-r\(.*\)-r\(.*\)/\2/g"`
  		gcnano_ver_Ra=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp\(.*\)-r\(.*\)-r\(.*\)/\3/g"`
  		gcnano_ver_Rb=`ls -1d ${component}-stm32mp-*-stm32mp*-r*-r* | sed -e "s/${component}-stm32mp-\(.*\)-stm32mp\(.*\)-r\(.*\)-r\(.*\)/\4/g"`
		gcnano_dir="${component}-stm32mp-${gcnano_ver}-stm32mp${gcnano_mp}-r${gcnano_ver_Ra}"
		;;
	"linux")
		linux_ver=${component_ver}
	  	linux_ver_Rb=${component_ver_Rb}
		linux_dir="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
	"tf-a")
	  	tfa_ver_Rb=${component_ver_Rb}
		tfa_dir="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
	"optee-os")
	  	optee_ver_Rb=${component_ver_Rb}
		optee_dir="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
	"u-boot")
	  	uboot_ver_Rb=${component_ver_Rb}
		uboot_dir="${component}-stm32mp-${component_ver}-stm32mp-r${component_ver_Ra}"
		;;
    esac
done

DO_CLEAN="1"
TRACK_ON_GIT="0"

dry_run=""
# dry_run="--dry-run"

if [ "x${DO_CLEAN}" == "x1" ]; then
   rm -rf "${tfa_dir}-r${tfa_ver_Rb}/${tfa_dir}"
   rm -rf "${optee_dir}-r${optee_ver_Rb}/${optee_dir}"
   rm -rf "${uboot_dir}-r${uboot_ver_Rb}/${uboot_dir}"
   rm -rf "${linux_dir}-r${linux_ver_Rb}/linux-${linux_ver}"
fi

folders_list="${devicetree_dir} ${gcnano_dir} ${linux_dir} ${optee_dir} ${tfa_dir} ${uboot_dir} ${ddrphy_dir}"

for folder in ${folders_list}; do
	[[ ! -d ${folder}-r${component_ver_Rb} ]] && continue
	cd ${folder}-r${component_ver_Rb}
	echo "Processing folder: ${folder}"
	echo -n "     Unpacking ..."
	archivename=${folder}-r${component_ver_Rb}

	[[ "x${archivename}" == "x${linux_dir}-r${linux_ver_Rb}" ]] && archivename="linux-${linux_ver}"
	tar xJf ${archivename}.tar.xz

	[[ "x${archivename}" == "x${tfa_dir}-r${tfa_ver_Rb}"     ]] && archivename=${folder}
	[[ "x${archivename}" == "x${optee_dir}-r${optee_ver_Rb}" ]] && archivename=${folder}
	[[ "x${archivename}" == "x${uboot_dir}-r${uboot_ver_Rb}" ]] && archivename=${folder}
	
	echo -n " Patching  ..."
	if [ `ls *patch 2>/dev/null | wc -l` -gt 0 ]; then
		cd ${archivename}
		if [ "x${TRACK_ON_GIT}" = "x1" ]; then
			test -d .git || git init . && git add . && git commit -m "${archivename} source code" && git checkout -b WORKING
		fi
		for patch in `ls ../*.patch`; do patch -p1 ${dry_run} < ${patch} >/dev/null 2>&1; echo -n "."; done
		[[ "x${archivename}" == "x${optee_dir}" ]] && tar xzf ../fonts.tar.gz
		cd ..
	fi
	echo -e "  Done.  \t--> Operation completed successfully."
	cd ..
done
