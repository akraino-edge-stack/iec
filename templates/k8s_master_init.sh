#!/bin/bash
set -ex
sudo sed -i 's@http://nova.clouds.archive.ubuntu.com@http://archive.ubuntu.com@g' /etc/apt/sources.list
sudo sed -i -e 's/^\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\([\t ]\+\)\(k8-master.*$\)/k8s_master_ip\2\3/g' /etc/hosts
apt update
pwd
# Looks like cloud-init does not set $HOME, so we can hack it into thinking it's /root
HOME=${HOME:-/root}
export HOME
git clone https://gerrit.akraino.org/r/iec
cd iec/scripts
./k8s_common.sh
./k8s_master.sh k8s_master_ip k8s_pod_net_cidr k8s_svc_net_cidr
. ${HOME}/.profile
sed -i 's@192.168.0.0/16@k8s_pod_net_cidr@g' cni/calico/calico.yaml
./setup-cni.sh k8s_cluster_ip
token=$(kubeadm token list --skip-headers | tail -1 | awk '{print $1}')
shaid=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d ' ' -f1)
echo "kubeadm join k8s_master_ip:6443 --token $token --discovery-token-ca-cert-hash sha256:$shaid" > /home/k8s_user/joincmd
cat /home/k8s_user/joincmd
./nginx.sh
./helm.sh
