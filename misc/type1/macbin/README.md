# Deploy Kubernetes and SEBA on MACCHIATObin

## Overview
The Marvell MACCHIATObin is a family of cost-effective and high-performance networking community
boards targeting ARM64bit high end networking and storage applications. With a offering that
include a fully open source software that include U-Boot, Linux, ODP and DPDK, the Marvell
MACCHIATObin are optimal platforms for community developers and Independent Software Vendors (ISVs)
to develop networking and storage applications. The default kernel configuration provided by
Marvell does not meet the container's system requirements. So need to reconfigure and compile
the kernel to meet SEBA operation，and also u-boot. We provide a kernel configuration file that
has been verified on the [MACCHIATObin][1] board for developers to use.

## Prerequisites
Marvell linux must apply with MUSDK provided kernel patches(see `patches/linux` in musdk repo
and relevant documentation).

U-boot version used: **u-boot-2018.03-armada-18.09**

Kernel version used: **linux-4.14.22-armada-18.09**

MUSDK version used: **musdk-armada-18.09**

## Build and Update Bootloader
Marvell provides detailed documentation on how to [build bootloaders from source code][2].
Note that checkout u-boot-2018.03-armada-18.09 branch is important. [This page][3] will
walk you through the bootloader update process via network, i.e. using the TFTP server.
In addition, you can use the USB Flash drive to update boot as following instructions:
```
Marvell>> usb reset
Marvell>> bubt flash-image.bin spi usb
Marvell>> reset
Marvell>> env default -a
Marvell>> env save
```
**Make sure that the MACCHIATObin board does not experience power loss during the entire
updating process, otherwise it will be bricked due to an unfinished bootloader update.**

## Setting U-Boot parameters
The U-Boot parameter for Micro SD card/USB boot can be found [here][4],but the instructions
of the page do not fully apply to 18.09.It needs to be changed a little bit.

Using Micro SD card:
```
Marvell>> setenv image_name boot/Image
Marvell>> setenv fdt_name boot/armada-8040-mcbin.dtb
Marvell>> setenv bootcmd 'mmc dev 1; ext4load mmc 1:1 $kernel_addr_r $image_name;ext4load \
mmc 1:1 $fdt_addr_r $fdt_name;setenv bootargs $console root=/dev/mmcblk1p1 rw rootwait \
pci=pcie_bus_safe cpuidle.off=1; booti $kernel_addr_r - $fdt_addr_r'
Marvell>> saveenv
Marvell>> run bootcmd
```
Using USB Stick:
```
Marvell>> setenv image_name boot/Image
Marvell>> setenv fdt_name boot/armada-8040-mcbin.dtb
Marvell>> setenv bootusb 'usb reset; ext4load usb 0:1 $kernel_addr_r $image_name; \
ext4load usb 0:1 $fdt_addr_r $fdt_name;setenv bootargs $console root=/dev/sda1 \
rw rootwait pci=pcie_bus_safe cpuidle.off=1;booti $kernel_addr_r - $fdt_addr_r'
Marvell>> saveenv
Marvell>> run bootusb
```
If U-Boot version is 17.10, you should repleace $kernel_addr_r/$fdt_addr_r by
$kernel_addr/$fdt_addr.

## Kernel compilation steps
The procedures to build kernel from source is almost the same, but there are still
some points you need to pay attention to on MACCHIATObin board.
Download Kernel Source:
```
mkdir -p ~/kernel/4.14.22
cd ~/kernel/4.14.22
git clone https://github.com/MarvellEmbeddedProcessors/linux-marvell .
git checkout linux-4.14.22-armada-18.09
```
Download MUSDK Package Marvell User-Space SDK(MUSDK) is a light-weight user-space I/O driver
for Marvell's Embedded Networking SoC's. The MUSDK library provides a simple and direct access
to Marvell's SoC blocks to networking applications and networking infrastrucutre:
```
mkdir -p ~/musdk
cd ~/musdk
git clone https://github.com/MarvellEmbeddedProcessors/musdk-marvell .
git checkout musdk-armada-18.09
```
Linux Kernel needs to be patched and built in order to run MUSDK on the MACCHIATObin board:
```
cd ~/kernel/4.14.22/
git am ~/musdk/patches/linux-4.14/*.patch
```
Replace the default kernel configuration file with defconfig-mcbin-edge which enable necessary
kernel modules needed by running kubernetes, also calico:
```
cp defconfig-mcbin-edge   ~/kernel/4.14.22/arch/arm64/configs/mvebu_v8_lsp_defconfig
```
and then compile the kernel:
```
export ARCH=arm64
make mvebu_v8_lsp_defconfig
make -j$(($(nproc)+1))
```
Script is provided to facilitate build of the kernel image, the developer needs to run with
root privileges:
```
./setup-macbin-kernel.sh
```

## Update the Kernel
If kernel is compiled on the MACCHIATObin board, you can easily update kernel using the
following instructions:
```
cd ~/kernel/4.14.22
make modules_install
cp ./arch/arm64/boot/Image /boot/
cp ./arch/arm64/boot/dts/marvell/armada-8040-mcbin.dtb  /boot/
sync
reboot
```
and also refer to the wiki for MACCHIATObin to [boot from removable storage][5].

## Install SEBA
SEBA as one of the IEC use cases, you can refer to [README][6] to manually install SEBA
on Arm servers.

[1]: http://macchiatobin.net
[2]: http://wiki.macchiatobin.net/tiki-index.php?page=Build+from+source+-+Bootloader#Build_U-Boot
[3]: http://wiki.macchiatobin.net/tiki-index.php?page=Update+the+Bootloader
[4]: http://wiki.macchiatobin.net/tiki-index.php?page=Boot+from+removable+storage+-+Ubuntu
[5]: http://wiki.macchiatobin.net/tiki-index.php?page=Boot+from+removable+storage+-+Ubuntu
[6]: ../../../src/use_cases/seba_on_arm/install/README
