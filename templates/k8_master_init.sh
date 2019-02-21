#!/bin/bash
set -x
apt update
pwd
# Looks like cloud-init does not set $HOME, so we can hack it into thinking it's /root
HOME=${HOME:-/root}
export HOME
git clone https://gerrit.akraino.org/r/iec
cd iec/scripts
./k8s_common.sh
./k8s_master.sh k8_master_ip k8_pod_net_cidr k8_svc_net_cidr
. ${HOME}/.profile
./cni/calico/calico.sh k8_cluster_ip
token=$(kubeadm token list --skip-headers | tail -1 | awk '{print $1}')
shaid=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d ' ' -f1)
echo "kubeadm join k8_master_ip:6443 --token $token --discovery-token-ca-cert-hash sha256:$shaid" > /home/ubuntu/joincmd
cat /home/ubuntu/joincmd
./nginx.sh
./helm.sh
