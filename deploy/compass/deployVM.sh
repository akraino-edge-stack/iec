#!/bin/bash
set -x

# Building compass
build_compass(){
  echo "*** begin Compass4nfv build:"

  # Fix bug of getting IP address failure.
  sed -i "s/inet addr:/inet /g" util/docker-compose/roles/compass/tasks/main.yml
  sed -i "s/cut -d: -f2/cut -d ' ' -f10/g" util/docker-compose/roles/compass/tasks/main.yml

  if [ ${HOST_ARCH} = 'aarch64' ]; then
    curl -s http://people.linaro.org/~yibo.cai/compass/compass4nfv-arm64-fixup.sh | bash || true
  fi

  ./build.sh |& tee log1-Build.txt
}

# Clear environments
clear_env(){

  if [ -d "${WORKSPACE}/compass4nfv" ]; then
    sudo rm -rf ${WORKSPACE}/compass4nfv
  fi

  if [ -d "${WORKSPACE}/iec" ]; then
    sudo rm -rf ${WORKSPACE}/iec
  fi
}

# Configure parameters of Arm VMs
config_arm(){
  # Remove the useless software list from software list( from line 28 to end).
  sed -i '28,$d' deploy/adapters/ansible/kubernetes/ansible-kubernetes.yml
  export ADAPTER_OS_PATTERN='(?i)ubuntu-16.04.*arm.*'
  export OS_VERSION="xenial"
  export KUBERNETES_VERSION="v1.13.0"

  export DHA="deploy/conf/vm_environment/k8-nosdn-nofeature-noha.yml"
  export NETWORK="deploy/conf/vm_environment/network.yml"
  export VIRT_NUMBER=2 VIRT_CPUS=4 VIRT_MEM=4096 VIRT_DISK=50G
}

# Configure parameters of x86 VMs
config_x86(){
  export NETWORK="deploy/conf/vm_environment/network.yml"
  export DHA="/deploy/conf/vm_environment/os-nosdn-nofeature-noha.yml"
  export OS_VERSION="xenial"
  export TAR_URL="file://${INSTALLDIR}/work/building/compass.tar.gz"

  sed -i '44,$d' deploy/adapters/ansible/openstack/HA-ansible-multinodes.yml

  sed -i '/export OPENSTACK_VERSION=queens/a export VIRT_NUMBER=2' deploy.sh
}

echo "*** begin AUTO install: OPNFV Compass4nfv"

# before starting, stop all the compass docker
sudo docker rm -f "$(sudo docker ps | grep compass | cut -f1 -d' ')" || true

# shellcheck disable=SC2164
WORKSPACE=$(cd "$(dirname "$0")";pwd)

clear_env

git clone https://gerrit.opnfv.org/gerrit/compass4nfv

# prepare install directory
INSTALLDIR=${WORKSPACE}/compass4nfv
HOST_ARCH=$(uname -m)

cd compass4nfv || exit

# launch build script
build_compass

# Configure parameters of VMs
if [ ${HOST_ARCH} = 'aarch64' ]; then
  config_arm
else
  config_x86
fi

# launch deploy script
echo "*** begin Compass4nfv deploy:"
./deploy.sh
