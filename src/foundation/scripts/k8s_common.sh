#!/bin/bash -ex

DOCKER_VERSION=18.06.1~ce~3-0~ubuntu
KUBE_VERSION=1.13.0-00
K8S_CNI_VERSION=0.6.0-00

# install the dns tools which will be used for cleaning
# the dns cache
refresh_dns(){
  sudo apt update
  sudo apt install -y nscd
  sudo /etc/init.d/nscd restart
  echo "sleep 10s ..."
  sleep 10
}

check_network(){

  HOST_LIST="www.google.com download.docker.com"

  for HOST in $HOST_LIST; do
    for NUM in $(seq 3); do
      if ping -c 1 $HOST > /dev/null; then
        NUM=1 # just in case ping is successful on the 3rd try
        echo "$HOST Ping is successful."
        break
      fi
    done
    if [ ${NUM} -eq 3 ];then
      echo "$HOST Ping failure!"
      refresh_dns
    fi
  done
}

# Before install enssential software, make sure the network is OK
check_network

# Install basic software
sudo apt update
sudo apt install -y software-properties-common apt-transport-https curl

# Install Docker as Prerequisite
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
  "deb https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"
sudo apt update
sudo apt install -y docker-ce=${DOCKER_VERSION}

# Disable swap on your machine
sudo swapoff -a

# Install Kubernetes with Kubeadm
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update
# Minor fix for broken kubernetes-cni dependency in upstream xenial repo
sudo apt install -y \
  kubernetes-cni=${K8S_CNI_VERSION} kubelet=${KUBE_VERSION} kubeadm=${KUBE_VERSION} kubectl=${KUBE_VERSION}
sudo apt-mark hold kubernetes-cni kubelet kubeadm kubectl

#Add extra flags to Kubelet
if ! grep -q -e 'fail-swap-on' /etc/default/kubelet; then
   sudo sed 's/KUBELET_EXTRA_ARGS=/KUBELET_EXTRA_ARGS=--fail-swap-on=false --feature-gates HugePages=false/' -i /etc/default/kubelet
fi

sudo modprobe br_netfilter
_conf='/etc/sysctl.d/99-akraino-iec.conf'
echo 'net.bridge.bridge-nf-call-iptables = 1' |& sudo tee "${_conf}"
sudo sysctl -q -p "${_conf}"
