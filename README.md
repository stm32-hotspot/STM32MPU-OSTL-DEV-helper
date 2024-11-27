# SDK_helper<br />
OpenSTLinux SDK tools<br />
##############################<br />

CONTENTS:<br />
  - folder <b>FLASH_LAYOUT</b>: flashlayout examples for writing tfa and FIP partitions;<br />
  - folder <b>KERNEL</b>: an example of minimal Linux KERNEL configuration for STM32MP2;<br />
  - folder <b>YOCTO</b>: a simple example of meta-layer that defines mymachine, myboard and external custom dts files;<br />
  - <b>unpack.sh</b>, <b>make_mp25x_FIP.sh</b>, <b>make_mp25x_KERNEL.sh</b>: set of scripts to simplify the usage of STM32MP2Dev OpenSTLinux Developer Package.


HOW TO USE the BUILD scripts::<br />
   Prerequisite:<br />
     - Download and extract STM32MP2Dev OpenSTLinux Developer Package<br />
          &nbsp;&nbsp;&nbsp;[Rif. https://www.st.com/en/embedded-software/stm32mp2dev.html]<br />
	  &nbsp;&nbsp;&nbsp;[Rif. https://wiki.st.com/stm32mpu/wiki/STM32MPU_Developer_Package]<br />
   
   Inside the folder where MP2-DEV-SRC package has been extracted<br />
     - Edit make_mp25x_FIP.sh and run ./make_mp25x_FIP.sh<br />
     - Edit make_mp25x_KERNEL.sh and run ./make_mp25x_KERNEL.sh<br />

<br />
Update uSDCard from Linux HOST PC::<br />
 - u-boot (FIP):<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/<PARTITION_5_OF_SDCARD_DEVICE> conv=sync<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/<PARTITION_6_OF_SDCARD_DEVICE> conv=sync<br />
	
 - Arm-Trusted-Firmware (TF-A):<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/<PARTITION_1_OF_SDCARD_DEVICE> conv=sync<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/<PARTITION_2_OF_SDCARD_DEVICE> conv=sync

<br />

Update eMMC from target board using the serial console command line:<br />
 - u-boot (FIP):<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/mmcblk0p3 conv=sync<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/mmcblk0p4 conv=sync

 - Arm-Trusted-Firmware (TF-A):<br />
	  echo 0 > /sys/block/mmcblk0boot0/force_ro<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/mmcblk0boot0 conv=sync<br />
	  echo 1 > /sys/block/mmcblk0boot0/force_ro

	  echo 0 > /sys/block/mmcblk0boot1/force_ro<br />
	  dd if=FIP_artifacts/fip-stm32mp257f-ev1-optee.bin of=/dev/mmcblk0boot1 conv=sync<br />
	  echo 1 > /sys/block/mmcblk0boot1/force_ro

<br />
Update Linux kernel and devicetree DTS file from target board using the serial console command line:<br />
 - Overwrite files in the /boot/ and /lib/modules/ folders on the target board.<b />
