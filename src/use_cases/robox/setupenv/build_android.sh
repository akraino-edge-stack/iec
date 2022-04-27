#!/bin/bash
set -e

ANDROID=anbox-work
ROBOX=robox
EXAGEAR=$ROBOX/Exagear

echo "please set git user and email. e.g."
echo git config --global user.email "you@example.com"
echo git config --global user.name "Your Name"
echo "make use both termial and git could accesss google.com, press enter to continue"
read

#if [ 0 -gt 1 ]; then
echo "prepare environment"
sudo sed -i "s/# deb-src/ deb-src/g" /etc/apt/sources.list
sudo apt update
sudo apt install -y openjdk-8-jdk
sudo apt install -y libx11-dev libreadline6-dev libgl1-mesa-dev g++-multilib
sudo apt install -y git flex bison gperf build-essential libncurses5-dev
sudo apt install -y tofrodos python-markdown libxml2-utils xsltproc zlib1g-dev
sudo apt install -y dpkg-dev libsdl1.2-dev
sudo apt install -y git-core gnupg flex bison gperf build-essential
sudo apt install -y zip curl zlib1g-dev gcc-multilib g++-multilib
sudo apt install -y libc6-dev
sudo apt install -y lib32ncurses5-dev x11proto-core-dev libx11-dev
sudo apt install -y libgl1-mesa-dev libxml2-utils xsltproc unzip m4
sudo apt install -y lib32z-dev ccache
sudo apt install -y bc python flex bison gperf libsdl-dev build-essential zip curl

if [ ! -d robox ]; then
echo "clone robox"
git clone https://github.com/kunpengcompute/robox.git
else
echo "robox directory exist, skip, clone robox"
fi

echo "try to clone Android"
if [ ! -x /usr/bin/repo ]; then
sudo apt install -y repo
#do not use the official repo because it it too new.
#if [ ! -x ~/bin/repo ]; then
#	  echo "get repo"
#	  mkdir ~/bin
#	  PATH=~/bin:$PATH
#	  curl https://storage.googleapis.com/git-repo-downloads/repo > ~/bin/repo
#	  chmod a+x ~/bin/repo
#	  echo "replace with python3"
#	  sed -i "s/#\!\/usr\/bin\/env python$/#\!\/usr\/bin\/env python3/g" ~/bin/repo
else
echo "repo exist, skip"
fi

if [ ! -d anbox-work ]; then
echo "clone anbox android code"
mkdir -p anbox-work
cd anbox-work
repo init -u https://github.com/anbox/platform_manifests.git -b anbox
# total disk size is about 160G
repo sync -j16
echo "fallback the code"
cp -p robox/binaryFiles/snapshot20191206.xml anbox-work/.repo/manifests/
cd anbox-work
repo init -m snapshot20191206.xml
repo sync --force-sync frameworks/opt/net/wifi
repo sync -d -j16
cd -
else
echo "anbox-work exist, skip to clone anbox android code"
echo "fallback the code locally"
cp -p robox/binaryFiles/snapshot20191206.xml anbox-work/.repo/manifests/
cd anbox-work
repo init -m snapshot20191206.xml
repo sync --force-sync frameworks/opt/net/wifi
repo sync -d -j16 --local-only
cd -
fi

echo "replace anbox code"
rm -rf $ANDROID/vendor/anbox
cp -rp $ROBOX $ANDROID/vendor/anbox
#fi # if [ 0 -gt 1 ]; then

echo "The exagear"
cp -p $EXAGEAR/android/android-7.1.1_r13.patch $ANDROID
cp -pr $EXAGEAR/android/vendor $ANDROID
ls $ANDROID/vendor/
#
cp -pr $ROBOX/patch/android-7.1.1_r13-V1.0/* $ANDROID
status=`cat script/status`
if [ ! "PATCH_ANDROID_DONE" == $status ]; then
echo "Patching Android"
cp -pr $ROBOX/patch/patch.sh $ANDROID
cd $ANDROID
sh patch.sh
echo PATCH_ANDROID_DONE > script/status
cd -
else
echo "Patch has already finished, skip patch"
fi

echo "build Android"
cd $ANDROID
#setup build environment
source build/envsetup.sh
#choose compile env
lunch anbox_arm64-userdebug
export JACK_EXTRA_CURL_OPTIONS=-k
export LC_ALL=C
make -j16

echo "generate the android.img"
cd vendor/anbox && ./scripts/create-package.sh $PWD/../../out/target/product/arm64/ramdisk.img $PWD/../../out/target/product/arm64/system.img
ls -lh android.img

