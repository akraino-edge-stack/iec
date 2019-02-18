#!/bin/bash
set -o xtrace

CLUSTER_IP=${1:-172.16.1.136} # Align with the value in our K8s setup script

# Install the Etcd Database
if [ "$(uname -m)" == 'aarch64' ]; then
  sed -i "s/10.96.232.136/${CLUSTER_IP}/" cni/calico/etcd-arm64.yaml
  kubectl apply -f cni/calico/etcd-arm64.yaml
else
  sed -i "s/10.96.232.136/${CLUSTER_IP}/" cni/calico/etcd-amd64.yaml
  kubectl apply -f cni/calico/etcd-amd64.yaml
fi


# Install the RBAC Roles required for Calico
kubectl apply -f "cni/calico/rbac.yaml"

# Install Calico to system
sed -i "s/10.96.232.136/${CLUSTER_IP}/" cni/calico/calico.yaml
kubectl apply -f cni/calico/calico.yaml

# Remove the taints on master node
kubectl taint nodes --all node-role.kubernetes.io/master- || true
