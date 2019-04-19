#!/bin/bash
set -ex
sed -i -e 's/^\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\([\t ]\+\)\(k8s_master_hostname.*$\)/k8s_master_ip\2\3/g' /etc/hosts
apt update
pwd
# Looks like cloud-init does not set $HOME, so we can hack it into thinking it's /root
HOME=${HOME:-/root}
export HOME
git clone https://gerrit.akraino.org/r/iec
cd iec/src/foundation/scripts
./k8s_common.sh
./k8s_master.sh k8s_master_ip k8s_pod_net_cidr k8s_svc_net_cidr
# shellcheck source=/dev/null
. ${HOME}/.profile
./setup-cni.sh k8s_cluster_ip k8s_pod_net_cidr
token=$(kubeadm token list --skip-headers | awk 'END{print $1}')
shaid=$(openssl x509 -in /etc/kubernetes/pki/ca.crt -noout -pubkey | openssl rsa -pubin -outform DER 2>/dev/null | sha256sum | cut -d ' ' -f1)
echo "kubeadm join k8s_master_ip:6443 --token $token --discovery-token-ca-cert-hash sha256:$shaid" > /home/k8s_user/joincmd
cat /home/k8s_user/joincmd
./nginx.sh
./helm.sh
