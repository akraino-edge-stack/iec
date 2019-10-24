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
K8S_MASTER_IP=${4:-10.169.41.173}
SERVICE_CIDR=${5:-172.16.1.0/24}
DEV_NAME=${6:-}

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

install_ovn_kubernetes(){
  # Update the ovn-kubernetes yaml files

  net_cidr_repl="{{ net_cidr | default('10.128.0.0/14/23') }}"
  svc_cidr_repl="{{ svc_cidr | default('172.30.0.0/16') }}"
  k8s_apiserver_repl="{{ k8s_apiserver.stdout }}"

  k8s_apiserver="https://${K8S_MASTER_IP}:6443"
  net_cidr="${POD_NETWORK_CIDR}"
  svc_cidr="${SERVICE_CIDR}"

  echo "net_cidr: ${net_cidr}"
  echo "svc_cidr: ${svc_cidr}"
  echo "k8s_apiserver: ${k8s_apiserver}"

  sed "s,${net_cidr_repl},${net_cidr},
  s,${svc_cidr_repl},${svc_cidr},
  s,${k8s_apiserver_repl},${k8s_apiserver}," \
  ${SCRIPTS_DIR}/cni/ovn-kubernetes/templates/ovn-setup.yaml.j2 > \
  ${SCRIPTS_DIR}/cni/ovn-kubernetes/yaml/ovn-setup.yaml

  # Install ovn-kubernetes by yaml files
  # shellcheck source=/dev/null
  source ${SCRIPTS_DIR}/cni/ovn-kubernetes/install-ovn-k8s.sh

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
 'ovn-kubernetes')
        echo "Install Ovn-Kubernetes ..."
        install_ovn_kubernetes
        ;;
 *)
        echo "${CNI_TYPE} is not supported"
        exit 1
        ;;
esac

# Remove the taints on master node
kubectl taint nodes --all node-role.kubernetes.io/master- || true
