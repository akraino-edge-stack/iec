#!/bin/bash
#Install the k8s-master & k8s-worker node from Mgnt node
#
set -e

#
# Displays the help menu.
#
display_help () {
  echo "Usage:"
  echo " "
  echo "This script can help you to deploy a simple iec testing"
  echo "environments."
  echo "Firstly, the master node and worker node information must"
  echo "be added into config file which will be used for deployment."
  echo ""
  echo "Secondly, there should be an user on each node which will be"
  echo "used to install the corresponding software on master and"
  echo "worker nodes. At the same time, this user should be enable to"
  echo "run the sudo command without input password on the hosts."
  echo " "
  echo "Example usages:"
  echo "   ./startup.sh"
}



#
# Deploy k8s with calico.
#
deploy_k8s () {
  set -o xtrace

  INSTALL_SOFTWARE="sudo apt-get update && sudo apt-get install -y git &&\
           sudo rm -rf ~/.kube ~/iec &&\
           git clone ${REPO_URL} &&\
           cd iec/src/foundation/scripts/ && source k8s_common.sh"

  #Automatic deploy the K8s environments on Master node
  SETUP_MASTER="cd iec/src/foundation/scripts/ && source k8s_master.sh ${K8S_MASTER_IP}"
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${INSTALL_SOFTWARE}
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_MASTER} | tee ${LOG_FILE}

  KUBEADM_JOIN_CMD=$(grep "kubeadm join " ./${LOG_FILE})


  #Automatic deploy the K8s environments on each worker-node
  SETUP_WORKER="cd iec/src/foundation/scripts/ && source k8s_worker.sh"

  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Install & Deploy on ${ip_addr}. password:${passwd}"

    sshpass -p ${passwd} ssh ${HOST_USER}@${ip_addr} ${INSTALL_SOFTWARE}
    sshpass -p ${passwd} ssh ${HOST_USER}@${ip_addr} "echo \"sudo ${KUBEADM_JOIN_CMD}\" >> ./iec/src/foundation/scripts/k8s_worker.sh"
    sshpass -p ${passwd} ssh ${HOST_USER}@${ip_addr} ${SETUP_WORKER}

  done


  #Deploy etcd & CNI from master node
  #There may be more options in future. e.g: Calico, Contiv-vpp, Ovn-k8s ...
  SETUP_CNI="cd iec/src/foundation/scripts && source setup-cni.sh"
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_CNI}
}

#
# Check the K8s environments
#
check_k8s_status(){
  set -o xtrace

  VERIFY_K8S="cd iec/src/foundation/scripts/ && source nginx.sh"
  sshpass -p ${K8S_MASTERPW} ssh ${HOST_USER}@${K8S_MASTER_IP} ${VERIFY_K8S}

  sleep 30
}


#
# Init
#
if [ $1 == "--help" ] || [ $1 == "-h" ];
then
  display_help
  exit 0
fi


# Read the configuration file
source config

echo "The number of K8s-Workers:${#K8S_WORKER_GROUP[@]}"

rm -f "${LOG_FILE}"

deploy_k8s

check_k8s_status
