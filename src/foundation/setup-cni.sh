#!/bin/bash
set -o xtrace
set -e

CLUSTER_IP=${1:-172.16.1.136} # Align with the value in our K8s setup script

# Install the Etcd Database
if [ "$(uname -m)" == 'aarch64' ]; then
  ETCD_YAML=etcd-arm64.yaml
else
  ETCD_YAML=etcd-amd64.yaml
fi

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

sed -i "s/10.96.232.136/${CLUSTER_IP}/" "${SCRIPTS_DIR}/cni/calico/${ETCD_YAML}"
kubectl apply -f "${SCRIPTS_DIR}/cni/calico/${ETCD_YAML}"

# Install the RBAC Roles required for Calico
kubectl apply -f "${SCRIPTS_DIR}/cni/calico/rbac.yaml"

# Install Calico to system
sed -i "s/10.96.232.136/${CLUSTER_IP}/" "${SCRIPTS_DIR}/cni/calico/calico.yaml"
kubectl apply -f "${SCRIPTS_DIR}/cni/calico/calico.yaml"

# Remove the taints on master node
kubectl taint nodes --all node-role.kubernetes.io/master- || true
