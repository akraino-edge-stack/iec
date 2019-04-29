#!/bin/bash
# Run the functest-kubernetes on master node for checking
# K8s environments
set -e

K8S_MASTER_IP=$1


if [ -z "${K8S_MASTER_IP}" ]
then
  echo "Error:K8S_MASTER_IP is empty."
  echo "Please input the k8s master ip address."
  echo "Just as:"
  echo "./functest.sh 10.1.1.1"
  exit 1
fi


cat <<EOF > "${HOME}/k8.creds"
export KUBERNETES_PROVIDER=local
export KUBE_MASTER_URL=https://${K8S_MASTER_IP}:6443
export KUBE_MASTER_IP=${K8S_MASTER_IP}
EOF

mkdir -p "${HOME}/functest/results"

echo "hello world"
sudo docker run --rm -e DEPLOY_SCENARIO=k8-nosdn-nofeature-noha \
       -v "${HOME}/k8.creds:/home/opnfv/functest/conf/env_file" \
       -v "${HOME}/functest/results:/home/opnfv/functest/results" \
       -v "${HOME}/.kube/config:/root/.kube/config" opnfv/functest-kubernetes-healthcheck:latest \
       /bin/bash -c 'run_tests -r -t all'
