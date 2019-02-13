#!/bin/bash -ex

DOCKER_VERSION=18.06.1~ce~3-0~ubuntu
KUBE_VERSION=1.13.0-00

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
sudo apt update
sudo apt install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
sudo apt update
sudo apt install -y \
  kubelet=${KUBE_VERSION} kubeadm=${KUBE_VERSION} kubectl=${KUBE_VERSION}
apt-mark hold kubelet kubeadm kubectl

_conf='/etc/sysctl.d/99-akraino-iec.conf'
echo 'net.bridge.bridge-nf-call-iptables = 1' |& sudo tee "${_conf}"
sudo sysctl -q -p "${_conf}"
