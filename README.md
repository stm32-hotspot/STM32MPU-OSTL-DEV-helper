# SDK_helper<br />
OpenSTLinux SDK tools<br />
##############################<br /><br />
HELPER SCRIPTs:
   - <b>unpack.sh</b>: Run this script one to unpack tar.xz archives or to cleanup the environment;<br />
   - <b>make_mp1_FIP.sh</b>, <b>make_mp1_KERNEL.sh</b>: Run theese scripts to generate TF-A, FIP and Linux kernel + modules for STM32MP1 boards;<br />
   - <b>make_mp2_FIP.sh</b>, <b>make_mp2_KERNEL.sh</b>: Run theese scripts to generate TF-A, FIP and Linux kernel + modules for STM32MP2 boards;<br />

CONFIGURATION VARIABLEs in make_ scripts:
   - <b>EXTDT_WORKING_DIR</b>: Defines the DEVICETREE path. (CubeMX project path is a valid value);<br />
   - <b>CUSTOM_DTS_NAME</b>: Defines the name of the custom devicetree;<br />

OTHER CONTENTs:<br />
  - folder <b>FLASH_LAYOUT</b>: flashlayout configurations for writing tfa and FIP partitions;<br />
  - folder <b>KERNEL</b>: minimal Linux KERNEL example configuration for STM32MP2;<br />
  - folder <b>YOCTO</b>: a simple example of meta-layer that defines mymachine, myboard and external custom dts files;<br />
  - folder <b>DEVICETREE</b>: External DEVICETREE examples;<br />
<br />
HOW TO USE the BUILD scripts::<br />
   Prerequisites:<br />
     - Download and extract STM32MP2Dev (or STM32MP1Dev) OpenSTLinux Developer Package<br />
          &nbsp;&nbsp;&nbsp;[Rif. https://www.st.com/en/embedded-software/stm32mp2dev.html]<br />
          &nbsp;&nbsp;&nbsp;[Rif. https://www.st.com/en/embedded-software/stm32mp1dev.html]<br />
	  &nbsp;&nbsp;&nbsp;[Rif. https://wiki.st.com/stm32mpu/wiki/STM32MPU_Developer_Package]<br />
   <br />

Enter inside the folder where "SOURCES-stm32mp-" package has been extracted<br />
(For example: "cd stm32mp-openstlinux-6.6-yocto-scarthgap-mpu-v25.06.11/sources/ostl-linux")<br /><br />
Clone this git  "gir clone https://github.com/stm32-hotspot/STM32MPU-OSTL-DEV-helper.git -b OpenSTLinux_v61"<br />
     - Configure ./STM32MPU-OSTL-DEV-helper/make_mp2_FIP.sh (or ./STM32MPU-OSTL-DEV-helper/make_mp1_FIP.sh ) and run it<br />
     - Configure ./STM32MPU-OSTL-DEV-helper/make_mp2_KERNEL.sh (or ./STM32MPU-OSTL-DEV-helper/make_mp1_KERNEL.sh) and run it<br />

<br />
HOW TO update uSDCard from Linux HOST PC::<br />
 - u-boot (FIP):<br />
	  dd if=BUILD_OUTPUT/fip/fip.bin of=/dev/<PARTITION_5_OF_SDCARD_DEVICE> conv=sync<br />
	  dd if=BUILD_OUTPUT/fip/fip.bin of=/dev/<PARTITION_6_OF_SDCARD_DEVICE> conv=sync<br />
	
 - Arm-Trusted-Firmware (TF-A):<br />
	  dd if=BUILD_OUTPUT/tfa/tfa_sdcard.stm32 of=/dev/<PARTITION_1_OF_SDCARD_DEVICE> conv=sync<br />
	  dd if=BUILD_OUTPUT/tfa/tfa_sdcard.stm32 of=/dev/<PARTITION_2_OF_SDCARD_DEVICE> conv=sync<br />

Update eMMC from target board using the serial console command line:<br />
 - u-boot (FIP):<br />
	  dd if=BUILD_OUTPUT/fip/fip.bin of=/dev/mmcblk0p3 conv=sync<br />
	  dd if=BUILD_OUTPUT/fip/fip.bin of=/dev/mmcblk0p4 conv=sync

 - Arm-Trusted-Firmware (TF-A):<br />
	  echo 0 > /sys/block/mmcblk0boot0/force_ro<br />
	  dd if=BUILD_OUTPUT/tfa/tfa_emmc.stm32 of=/dev/mmcblk0boot0 conv=sync<br />
	  echo 1 > /sys/block/mmcblk0boot0/force_ro

	  echo 0 > /sys/block/mmcblk0boot1/force_ro<br />
	  dd if=BUILD_OUTPUT/tfa/tfa_emmc.stm32 of=/dev/mmcblk0boot1 conv=sync<br />
	  echo 1 > /sys/block/mmcblk0boot1/force_ro

<br />
Update Linux kernel and devicetree DTS file from target board using the serial console command line:<br />
 - Overwrite files in the /boot/ and /lib/modules/ folders on the target board.<b />
