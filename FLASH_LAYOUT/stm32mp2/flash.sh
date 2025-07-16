#!/bin/bash -e

export PATH=$PATH:/opt/st/STM32Prog/bin/

STORAGE="emmc"
# STORAGE="sdcard"

STM32_Programmer_CLI -c port=USB1 -w FLASH_LAYOUT/flash_layout_${STORAGE}.tsv

