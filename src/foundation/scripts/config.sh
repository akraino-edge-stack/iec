#!/bin/bash
# shellcheck disable=SC2034

# Host user which can log into master and each worker nodes
HOST_USER=${HOST_USER:-iec}

REPO_URL="https://gerrit.akraino.org/r/iec"
#log file
LOG_FILE="kubeadm.log"


# Master node IP address
K8S_MASTER_IP="10.169.36.152"

# HOST_USER's password on Master node
K8S_MASTERPW="123456"

######################################################
#
#  K8S_WORKER_GROUP is an array which consists of 2
#  parts. One is k8s worker ip address. The other is
#  the user password.
#
######################################################
K8S_WORKER_GROUP=(
"10.169.40.106,123456"
)


