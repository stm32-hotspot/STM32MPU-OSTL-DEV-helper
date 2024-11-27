
"C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe" -c port=USB1 -d arm-trusted-firmware\tf-a-stm32mp257f-myboard-optee-programmer-usb.stm32 0x1 -s 0x1 -d fip\fip-stm32mp257f-myboard-ddr-optee-programmer-usb.bin 0x2 -s 0x2 -d fip\fip-stm32mp257f-myboard-optee-emmc.bin 0x3 -s 0x3 -d scripts\script.bin 0x0 -s 0x0 --detach 

timeout /t 2

"C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe" -c port=USB1 -w scripts\Flashlayout_ramfs.tsv

"C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe" -c port=USB1 --detach
