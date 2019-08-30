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
  echo ""
  echo "In the end, some optional parameters could be directly passed"
  echo "to startup.sh by shell for easy customizing your own IEC"
  echo "environments:"
  echo "-k|--kube:      ---- The version of k8s"
  echo "-c|--cni-ver:   ---- Kubernetes-cni version"
  echo "-C|--cni:       ---- CNI type: calico/flannel"
  echo ""
  echo "Example usages:"
  echo "   ./startup.sh #Deploy with default parameters"
  echo "    #Deploy the flannel with 1.15.2 K8s"
  echo "   ./startup.sh -C flannel -k 1.15.2 -c 0.7.5"
  exit
}



#
# Deploy k8s.
#
deploy_k8s () {
  set -o xtrace

  INSTALL_SOFTWARE="sudo apt-get update && sudo apt-get install -y git &&\
           sudo rm -rf ~/.kube ~/iec &&\
           git clone ${REPO_URL} &&\
           cd iec/src/foundation/scripts/ && source k8s_common.sh $KUBE_VERSION $CNI_VERSION"

  #Automatic deploy the K8s environments on Master node
  SETUP_MASTER="cd iec/src/foundation/scripts/ && source k8s_master.sh ${K8S_MASTER_IP}"
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${INSTALL_SOFTWARE}
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_MASTER} | tee ${LOG_FILE}

  TOKEN=$(grep "\--token " ./${LOG_FILE})
  TOKEN_ID=$(echo ${TOKEN#*"token "}|cut -f1 -d' ')

  SH256=$(grep "\--discovery-token-ca-cert-hash " ./${LOG_FILE})
  TOKEN_CA_SH256=${SH256#*"sha256:"}

  KUBEADM_JOIN_CMD="kubeadm join ${K8S_MASTER_IP}:6443 --token ${TOKEN_ID} --discovery-token-ca-cert-hash sha256:${TOKEN_CA_SH256}"

  #Automatic deploy the K8s environments on each worker-node
  SETUP_WORKER="cd iec/src/foundation/scripts/ && source k8s_worker.sh"

  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Install & Deploy on ${ip_addr}. password:${passwd}"

    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} ${INSTALL_SOFTWARE}
    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} "echo \"sudo ${KUBEADM_JOIN_CMD}\" >> ./iec/src/foundation/scripts/k8s_worker.sh"
    sleep 2
    if [ -n "${CNI_TYPE}" ] && [ ${CNI_TYPE} == "contivpp" ] && [ -n "${DEV_NAME[$ip_addr]}" ]
    then
      CONTIVPP_CONFIG="cd iec/src/foundation/scripts/cni/contivpp && sudo ./contiv-update-config.sh ${DEV_NAME[$ip_addr]}"
      sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} $CONTIVPP_CONFIG
    fi
    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} "sudo swapon -a"
    sshpass -p ${passwd} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${ip_addr} ${SETUP_WORKER}

  done


  #Deploy etcd & CNI from master node
  SETUP_CNI="cd iec/src/foundation/scripts && source setup-cni.sh $CLUSTER_IP $POD_NETWORK_CIDR $CNI_TYPE"
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_CNI}
  SETUP_HELM="cd iec/src/foundation/scripts && source helm.sh"
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_HELM}

}

#
# Check the K8s environments
#
check_k8s_status(){
  set -o xtrace

  VERIFY_K8S="cd iec/src/foundation/scripts/ && source nginx.sh"
  sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${VERIFY_K8S}
}

#
# print environments
#
printOption(){
  echo "K8S_MASTER_IP:${K8S_MASTER_IP}"
  echo "HOST_USER:${HOST_USER}"
  echo "REPO_URL:${REPO_URL}"

  echo "The number of K8s-Workers:${#K8S_WORKER_GROUP[@]}"
  for worker in "${K8S_WORKER_GROUP[@]}"
  do
    ip_addr="$(cut -d',' -f1 <<<${worker})"
    passwd="$(cut -d',' -f2 <<<${worker})"
    echo "Install & Deploy on ${ip_addr}. password:${passwd}"
  done

  echo "KUBE_VERSION: ${KUBE_VERSION}"
  echo "CNI_TPYE: ${CNI_TYPE}"
  echo "CLUSTER_IP: ${CLUSTER_IP}"
  echo "POD_NETWORK_CIDR: ${POD_NETWORK_CIDR}"
}

# Read the configuration file
source config

rm -f "${LOG_FILE}"

ARGS=`getopt -a -o C:k:c:h -l cni:,kube:,cni-ver:,help -- "$@"`
eval set -- "${ARGS}"
while true
do
        case "$1" in
        -C|--cni)
                CNI_TYPE="$2"
                echo "CNI_TYPE=$2"
                shift
                ;;
        -k|--kube)
                echo "This is config kube version:$2"
                KUBE_VERSION="$2"
                shift
                ;;
        -c|--cni-ver)
                echo "This is config cni version:$2"
                CNI_VERSION="$2"
                shift
                ;;
        -h|--help)
                echo "this is help case"
                display_help
                ;;
        --)
                printOption
                shift
                break
                ;;
        esac
shift
done

deploy_k8s

sleep 20

check_k8s_status
