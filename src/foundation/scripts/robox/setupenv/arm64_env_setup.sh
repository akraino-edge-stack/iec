#!/bin/bash

set -e

ROBOX_SRC=download/robox

stage1(){
	echo "Enable source"
	sudo sed -i "s/^# deb-src/ deb-src/g" /etc/apt/sources.list
	echo "update"
	sudo apt update

	echo "Install dependency"
	sudo apt install -y dpkg libncurses5-dev libncursesw5-dev libssl-dev cmake cmake-data debhelper dbus google-mock libboost-dev libboost-filesystem-dev libboost-log-dev libboost-iostreams-dev libboost-program-options-dev libboost-system-dev libboost-test-dev libboost-thread-dev libcap-dev libsystemd-dev libdbus-1-dev libegl1-mesa-dev  libgles2-mesa-dev libglib2.0-dev libglm-dev libgtest-dev liblxc1 libproperties-cpp-dev libprotobuf-dev libsdl2-dev libsdl2-image-dev lxc-dev pkg-config protobuf-compiler

	#TODO compare "Ubuntu 18.04.1 LTS \n \l" in /etc/issue
	sudo apt install -y libboost-filesystem1.62.0 libboost-system1.62.0 docker.io dkms libboost-iostreams1.62.0

	sudo apt install -y build-essential
	sudo apt install -y mesa-common-dev

	echo "install libprocess-cpp3 and libdbus(and dev)"
	#TODO compare "Ubuntu 18.04.1 LTS \n \l" in /etc/issue
	wget http://launchpadlibrarian.net/291649807/libprocess-cpp3_3.0.1-0ubuntu5_arm64.deb
	wget http://launchpadlibrarian.net/291804794/libdbus-cpp5_5.0.0+16.10.20160809-0ubuntu2_arm64.deb
	wget http://launchpadlibrarian.net/291804785/libdbus-cpp-dev_5.0.0+16.10.20160809-0ubuntu2_arm64.deb
	sudo dpkg -i libprocess-cpp3_3.0.1-0ubuntu5_arm64.deb
	sudo dpkg -i libdbus-cpp5_5.0.0+16.10.20160809-0ubuntu2_arm64.deb
	sudo dpkg -i libdbus-cpp-dev_5.0.0+16.10.20160809-0ubuntu2_arm64.deb
	rm libprocess-cpp3_3.0.1-0ubuntu5_arm64.deb
	rm libdbus-cpp5_5.0.0+16.10.20160809-0ubuntu2_arm64.deb
	rm libdbus-cpp-dev_5.0.0+16.10.20160809-0ubuntu2_arm64.deb

	echo "Check docker storage driver type"
	STORAGE_DRV=`sudo docker info |grep Storage | sed "s/\ //g" | cut -d : -f 2`
	if [ "$STORAGE_DRV" == "overlay2" ] || [ "$STORAGE_DRV" == "overlay" ]; then
	echo "Docker Storage driver ok"
	else
	echo "ERROR: docker storage driver should be overlay2"
	exit
	fi

	echo install desktop
	sudo apt install -y xfce4  xfce4-* xrdp

	echo "setup remote desktop"
	echo "enable remote desktop for current user"
	echo "xfce4-session" > ~/.xsession
	echo "enable remote desktop for root"
	sudo su -c 'echo "xfce4-session" > /root/.xsession'
	sudo /etc/init.d/xrdp restart

	echo "Install the current latest kernel in ubuntu 18.04.1"
	#sudo apt install -y linux-generic=4.15.0.163.152
	echo "Please reboot to continue, or the location of kernel module might be wrong!"
	exit
}

stage2() {
	echo "Install kernel source"
	sudo apt install linux-source-4.15.0

	echo "downloading robox"
	if [ -d "$ROBOX_SRC" ]; then
		pushd $ROBOX_SRC
		COMMIT=`git log --oneline -n1  e74a3c6cb1be683d31f742b2c8344d0e28577536`
		if [ "$COMMIT" != "" ]; then
			echo "robox exist, skip git clone"
		else
			cd ..
			rm -rf robox
			git clone https://github.com/kunpengcompute/robox.git 
			cd robox
		fi
	else
		mkdir -p download
		pushd download
		git clone https://github.com/kunpengcompute/robox.git 
		cd robox
	fi
	echo "checkout to tested commit"
	git checkout -f e74a3c6cb1be683d31f742b2c8344d0e28577536
	popd

	echo "build anbox module"
	pushd $ROBOX_SRC/kernel/robox-modules/
	sudo mkdir -p /etc/modules-load.d/
	sudo cp -p anbox.conf /etc/modules-load.d/
	sudo cp -p 99-anbox.rules /lib/udev/rules.d/
	sudo cp -prT ashmem /usr/src/anbox-ashmem-1
	sudo cp -prT binder /usr/src/anbox-binder-1
	sudo dkms install anbox-ashmem/1
	sudo dkms install anbox-binder/1
	popd

	echo "Install ashmem and binder modules"
	sudo modprobe ashmem_linux
	sudo rmmod binder_linux || true; sudo modprobe binder_linux num_devices=254
	echo "check if module insert correctly"
	lsmod|grep -e ashmem_linux -e binder_linux
	sudo chmod 777 /dev/ashmem /dev/binder*
	echo "Press any key to continue"
	read

	echo "build robox"
	mkdir -p download/robox/build
	pushd download/robox/build
	cmake ..
	echo "TODO: make it to idempotent"
	sudo sed -i "s/^\#ifndef GLM_ENABLE_EXPERIMENTAL/\#define GLM_ENABLE_EXPERIMENTAL\n\#ifndef GLM_ENABLE_EXPERIMENTAL/g" /usr/include/glm/gtx/transform.hpp
	make -j5
	sudo make install
	popd

	echo "Enable graphics"
	sudo apt install -y xfce4 mesa-utils x11vnc vainfo

	echo "STEP: Installation mesa. mesa is a OpenGL library"
	echo "### Clone mesa ###"
	mkdir -p sources
	pushd sources
	if [ ! -d mesa ]; then
		sudo apt-get install -y apt-transport-https ca-certificates
		sudo update-ca-certificates 
		git clone https://anongit.freedesktop.org/git/mesa/mesa.git
	fi
	cd mesa
	git checkout -f mesa-19.0.8

	echo "### Build mesa ###"
	sudo apt build-dep -y mesa
	sudo apt install -y libomxil-bellagio-dev libva-dev  llvm-7  llvm-7-dev python-mako
	./autogen.sh  --enable-texture-float --with-gallium-drivers=radeonsi,swrast --with-dri-drivers=radeon,swrast --with-platforms=drm,x11 --enable-glx-tls --enable-shared-glapi --enable-dri3 --enable-lmsensors  --enable-gbm --enable-xa --enable-osmesa  --enable-vdpau --enable-nine --enable-omx-bellagio --enable-va --with-llvm-prefix=/usr/lib/llvm-7 --enable-llvm --target=aarch64-linux-gnu CFLAGS="-fsigned-char -O2" CPPFLAGS="-fsigned-char -O2" CXXFLAGS="-fsigned-char -O2" --enable-autotools
	make -j5 && sudo make install
	echo "TODO: make it to idempotent"
	sudo sed -i "s/^/\/usr\/local\/lib\n/g" /etc/ld.so.conf
	sudo ldconfig
	popd
}

setup_android_image() {
	echo "Downloading Android image"
	ANDROID_IMG=android.img
	ANDROID_MD5=`md5sum $ANDROID_IMG | cut -d \  -f 1`
	if [ "$ANDROID_MD5" = "fc44fce9ddfcdca737200468bcb5615e" ]; then
		echo "Huawei Android image already exist, skip download"
	elif [ -f images/android.img ]; then
		echo "Another Android image exist, skip download"
		ANDROID_IMG=android.img
	else
		mkdir -p images
		wget https://mirrors.huaweicloud.com/kunpeng/archive/kunpeng_solution/native/android.img -o images/android.img
		echo "Downloaded"
	fi

	mkdir -p images/android
	sudo mount images/$ANDROID_IMG images/android
	pushd images/android
	sudo tar --numeric-owner -cf - . | sudo docker import - android:robox
	popd
	sudo umount images/android
}

configure_gpu(){
	sudo cp -p script/xorg.conf /etc/X11
	IDS=`lspci |grep AMD.*7100 | cut -d \  -f 1 | sed "s/[:.]/ /g"`
	BUSID= ;for id in $IDS; do BUSID+=`echo -n "$((16#$id)) "`; done
	BUSID=`echo $BUSID | sed "s/ /:/g" | sed "s/ $//g"`
	sudo sed -i "s/BusID \"pci:.*:.*:.*\"\ *$/BusID \"pci:$BUSID\"/g" /etc/X11/xorg.conf
}

echo "SHOULD Allow apt installer restart service without prompt"
stage1
stage2
setup_android_image
configure_gpu
