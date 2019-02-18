#!/bin/bash
#Install the k8s-master & k8s-worker node from Mgnt node
#
set -e

#
# Displays the help menu.
#
display_help () {
  echo "Usage: $0 [master ip] [worker ip] [password] "
  echo " "
  echo "There should be an 'iec' user which will be used to install "
  echo "corresponding software on master & worker node. This user can "
  echo "run the sudo command without input password on the hosts."
  echo " "
  echo "Example usages:"
  echo "   ./startup.sh 10.169.40.171 10.169.41.172 123456"
}



#
# Deploy k8s with calico.
#
deploy_k8s () {
	set -o xtrace

	#Automatic deploy the K8s environments on Master node
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "sudo apt-get update"
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "sudo apt-get install -y git"
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "sudo rm -rf ~/.kube ~/iec"
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "git clone ${REPO_URL}"
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "cd iec/scripts/ && source k8s_common.sh"
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "cd iec/scripts/ && source k8s_master.sh ${K8S_MASTER_IP}" | tee kubeadm.log

	KUBEADM_JOIN_CMD=$(grep "kubeadm join " ./kubeadm.log)

	#Automatic deploy the K8s environments on Worker node
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "sudo apt-get update"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "sudo apt-get install -y git"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "sudo rm -rf ~/.kube ~/iec"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "git clone ${REPO_URL}"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "cd iec/scripts/ && source k8s_common.sh"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "echo \"sudo ${KUBEADM_JOIN_CMD}\" >> ./iec/scripts/k8s_worker.sh"
	sshpass -p ${K8S_WORKERPW} ssh ${HOST_USER}@${K8S_WORKER01_IP} "cd iec/scripts/ && source k8s_worker.sh"


	#Deploy etcd & CNI from master node
	sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} "cd iec/scripts && source setup-cni.sh"
}


PASSWD=${3:-"123456"}
HOST_USER="iec"

K8S_MASTER_IP=${1:-"10.169.40.171"}
K8S_MASTERPW=${PASSWD}

K8S_WORKER01_IP=${2:-"10.169.41.172"}
K8S_WORKERPW=${PASSWD}

REPO_URL="https://gerrit.akraino.org/r/iec"
LOG_FILE="kubeadm.log"

if [ -f "./kubeadm.log" ]; then
	rm kubeadm.log
fi

#
# Init
#
if [ $# -lt 3 ]
then
  display_help
  exit 0
fi


deploy_k8s
