#!/bin/bash
set -o xtrace
set -e

if [ -f "$HOME/.bashrc" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"
fi


CLUSTER_IP=${1:-172.16.1.136} # Align with the value in our K8s setup script
POD_NETWORK_CIDR=${2:-192.168.0.0/16}
CNI_TYPE=${3:-calico}
DEV_NAME=${4:-}

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

install_calico(){
  # Install the Etcd Database
  ETCD_YAML=etcd.yaml

  sed -i "s/10.96.232.136/${CLUSTER_IP}/" "${SCRIPTS_DIR}/cni/calico/${ETCD_YAML}"
  kubectl apply -f "${SCRIPTS_DIR}/cni/calico/${ETCD_YAML}"

  # Install the RBAC Roles required for Calico
  kubectl apply -f "${SCRIPTS_DIR}/cni/calico/rbac.yaml"

  # Install Calico to system
  sed -i "s@10.96.232.136@${CLUSTER_IP}@; s@192.168.0.0/16@${POD_NETWORK_CIDR}@" \
    "${SCRIPTS_DIR}/cni/calico/calico.yaml"
  kubectl apply -f "${SCRIPTS_DIR}/cni/calico/calico.yaml"
}

install_flannel(){
  # Install the flannel CNI
  sed -i "s@10.244.0.0/16@${POD_NETWORK_CIDR}@" "${SCRIPTS_DIR}/cni/flannel/kube-flannel.yml"
  kubectl apply -f "${SCRIPTS_DIR}/cni/flannel/kube-flannel.yml"
}

install_contivpp(){
  # Update vpp config file
  ${SCRIPTS_DIR}/cni/contivpp/contiv-update-config.sh $DEV_NAME

  # Install contivpp CNI
  sed -i "s@10.1.0.0/16@${POD_NETWORK_CIDR}@" "${SCRIPTS_DIR}/cni/contivpp/contiv-vpp.yaml"
  kubectl apply -f "${SCRIPTS_DIR}/cni/contivpp/contiv-vpp.yaml"
}

case ${CNI_TYPE} in
 'calico')
        echo "Install calico ..."
        install_calico
        ;;
 'flannel')
        echo "Install flannel ..."
        install_flannel
        ;;
 'contivpp')
        echo "Install Contiv-VPP ..."
        install_contivpp
        ;;
 *)
        echo "${CNI_TYPE} is not supported"
        exit 1
        ;;
esac

# Remove the taints on master node
kubectl taint nodes --all node-role.kubernetes.io/master- || true
