stm32prog usb 0;
setenv bootargs "root=/dev/ram0 rootfstype=ramfs rw initrd=0x90400000,128M init=/bin/sh rootwait quiet";
booti ${kernel_addr_r} - ${fdt_addr_r};
