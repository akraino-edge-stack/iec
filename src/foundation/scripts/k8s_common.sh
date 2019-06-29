#!/bin/bash -ex

DOCKER_VERSION=18.06.1~ce~3-0~ubuntu
KUBE_VERSION=1.13.0-00
K8S_CNI_VERSION=0.6.0-00

ping_success_status() {
  if ping -c 1 $1 >/dev/null; then
    echo "$1 Ping is successful."
    continue
  fi
}

refresh_dns(){
  sudo apt update
  sudo apt install -y nscd
  sudo /etc/init.d/nscd restart
  echo "sleep 10s ..."
  sleep 10
  break
}

check_network(){

  IP_LIST="www.google.com download.docker.com"

  for IP in $IP_LIST; do
    ping_success_status $IP
    echo "$IP ping is failed 1st times"
    ping_success_status $IP
    echo "$IP ping is failed 2ed times"
    ping_success_status $IP
    echo "$IP Ping is failure!"
    refresh_dns
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
