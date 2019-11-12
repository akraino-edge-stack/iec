#!/bin/bash
set -x
#Uninstall the k8s-master & k8s-worker node from Mgnt node
#

#
# Destroy k8s.
#
Destroy_k8s(){

  KUBEADM_DESTROY_CMD="kubeadm reset -f"

  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Destroy k8s on ${ip_addr}. password:${passwd}"

    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} ${KUBEADM_DESTROY_CMD}
    sleep 2
  done

  #Destroy master k8s env
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${KUBEADM_DESTROY_CMD}
}


#
# Uninstall software.
#
Uninstall () {
  UNINSTALL_CMD="sudo apt purge -y kubernetes-cni kubeadm kubectl kubelet docker-ce --allow-change-held-packages"
  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Destroy k8s on ${ip_addr}. password:${passwd}"

    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} "${UNINSTALL_CMD}"
    sleep 2
  done

  #master k8s env
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} "${UNINSTALL_CMD}"
}


#
# Recover system configuration.
#
Recover_conf(){

  REC_CMD="sudo swapon -a"

  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Destroy k8s on ${ip_addr}. password:${passwd}"

    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} "${REC_CMD}"
    sleep 2
  done

  #master k8s env
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} "${REC_CMD}"
}

# Read the configuration file
source config

Destroy_k8s

Uninstall
sleep 10

Recover_conf
sleep 20
