#!/bin/bash -e


gcnano_ver="6.4.19"
linux_ver="6.6.48"
optee_ver="4.0.0"
tfa_ver="v2.10.5"
ddr_ver="A2022.11"
uboot_ver="v2023.10"
devicetree_ver="6.0"

R0="-r0"
R1="-r1"
R2="-r2"
RC8="-rc8"

devicetree_dir="external-dt-${devicetree_ver}"
gcnano_dir="gcnano-driver-stm32mp-${gcnano_ver}-stm32mp2${R1}${RC8}"
linux_dir="linux-stm32mp-${linux_ver}-stm32mp${R1}"
optee_dir="optee-os-stm32mp-${optee_ver}-stm32mp${R1}"
tfa_dir="tf-a-stm32mp-${tfa_ver}-stm32mp${R1}"
uboot_dir="u-boot-stm32mp-${uboot_ver}-stm32mp${R1}"
ddr_dir="stm32mp-ddr-phy-${ddr_ver}"

DO_CLEAN="1"
TRACK_ON_GIT="0"

dry_run=""
# dry_run="--dry-run"

if [ "x${DO_CLEAN}" == "x1" ]; then
   rm -rf "${tfa_dir}${R0}/${tfa_dir}"
   rm -rf "${optee_dir}${R0}/${optee_dir}"
   rm -rf "${uboot_dir}${R0}/${uboot_dir}"
   rm -rf "${linux_dir}${R0}/linux-${linux_ver}"
fi

folders_list="${devicetree_dir} ${gcnano_dir} ${linux_dir} ${optee_dir} ${tfa_dir} ${uboot_dir} ${ddr_dir}"

for folder in ${folders_list}; do
	cd ${folder}${R0}
	echo "Processing folder: ${folder}"
	echo -n "     Unpacking ..."
	archivename=${folder}${R0}

	[[ "x${archivename}" == "x${linux_dir}${R0}" ]] && archivename="linux-${linux_ver}"
	tar xJf ${archivename}.tar.xz

	[[ "x${archivename}" == "x${tfa_dir}${R0}" ]] 	&& archivename=${folder}
	[[ "x${archivename}" == "x${optee_dir}${R0}" ]] && archivename=${folder}
	[[ "x${archivename}" == "x${uboot_dir}${R0}" ]] && archivename=${folder}
	
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
