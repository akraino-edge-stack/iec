#!/bin/bash -ex

CLUSTER_IP=${1:-172.16.1.136} # Align with the value in our K8s setup script
CALICO_URI_ROOT=https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation

# Install the Etcd Database
if [ "$(uname -m)" == 'aarch64' ]; then
  ETCD_YAML=https://raw.githubusercontent.com/Jingzhao123/arm64TemporaryCalico/temporay_arm64/v3.3/getting-started/kubernetes/installation/hosted/etcd-arm64.yaml
else
  ETCD_YAML=${CALICO_URI_ROOT}/hosted/etcd.yaml
fi
wget -O etcd.yaml "${ETCD_YAML}"
sed -i "s/10.96.232.136/${CLUSTER_IP}/" etcd.yaml
kubectl apply -f etcd.yaml

# Install the RBAC Roles required for Calico
kubectl apply -f "${CALICO_URI_ROOT}/rbac.yaml"

# Install Calico to system
wget -O calico.yaml "${CALICO_URI_ROOT}/hosted/calico.yaml"
sed -i "s/10.96.232.136/${CLUSTER_IP}/" calico.yaml
if [ "$(uname -m)" == 'aarch64' ]; then
  sed -i "s/quay.io\/calico/calico/" calico.yaml
fi
# FIXME: IP_AUTODETECTION_METHOD?
kubectl apply -f calico.yaml

# Remove the taints on master node
kubectl taint nodes --all node-role.kubernetes.io/master- || true
