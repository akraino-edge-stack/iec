#!/bin/bash
#Install the k8s-master & k8s-worker node from Mgnt node
#
set -e

#
# Displays the help menu.
#
display_help () {
  echo "Usage: $0 [master ip] [worker ip] [user] [password] "
  echo " "
  echo "There should be an user which will be used to install the "
  echo "corresponding software on master & worker node. This user can "
  echo "run the sudo command without input password on the hosts."
  echo " "
  echo "Example usages:"
  echo "   ./startup.sh 10.169.40.171 10.169.41.172 iec 123456"
}



#
# Deploy k8s with calico.
#
deploy_k8s () {
  set -o xtrace

  INSTALL_SOFTWARE="sudo apt-get update && sudo apt-get install -y git &&\
           sudo rm -rf ~/.kube ~/iec &&\
           git clone ${REPO_URL} &&\
           cd iec/scripts/ && source k8s_common.sh"

  #Automatic deploy the K8s environments on Master node
  SETUP_MASTER="cd iec/scripts/ && source k8s_master.sh ${K8S_MASTER_IP}"
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${INSTALL_SOFTWARE}
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_MASTER} | tee kubeadm.log

  KUBEADM_JOIN_CMD=$(grep "kubeadm join " ./kubeadm.log)

  #Automatic deploy the K8s environments on Worker node
  SETUP_WORKER="cd iec/scripts/ && source k8s_worker.sh"
  sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} ${INSTALL_SOFTWARE}
  sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "echo \"sudo ${KUBEADM_JOIN_CMD}\" >> ./iec/scripts/k8s_worker.sh"
  sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} ${SETUP_WORKER}

  #Deploy etcd & CNI from master node
  #There may be more options in future. e.g: Calico, Contiv-vpp, Ovn-k8s ...
  SETUP_CNI="cd iec/scripts && source setup-cni.sh"
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_CNI}
}


PASSWD=${4:-"123456"}
HOST_USER=${3:-"iec"}

K8S_MASTER_IP=${1:-"10.169.40.171"}
K8S_MASTERPW=${PASSWD}

K8S_WORKER01_IP=${2:-"10.169.41.172"}
K8S_WORKERPW=${PASSWD}

REPO_URL="https://gerrit.akraino.org/r/iec"
LOG_FILE="kubeadm.log"

if [ -f "./${LOG_FILE}" ]; then
  rm "${LOG_FILE}"
fi

#
# Init
#
if [ $# -lt 4 ]
then
  display_help
  exit 0
fi


deploy_k8s
