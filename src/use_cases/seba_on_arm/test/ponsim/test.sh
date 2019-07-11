#!/bin/bash
# shellcheck disable=SC2016

set -ex

basepath=$(cd "$(dirname "$0")"; pwd)

CORD_IMG="${CORD_IMG:-akraino/validation:cord-tester-latest}"
KUBE_DIR="${KUBE_DIR:-${PWD}/.kube}"
K8S_MASTER="${K8S_MASTER:-127.0.0.1}"
TEST_USER="${TEST_USER:-ubuntu}"

cont_id=
trap f_clean INT EXIT

f_clean(){
  echo "Cleaning up after ${cont_id}"
  docker kill "${cont_id}"
  docker rm "${cont_id}"
}

if ! [ -d "${KUBE_DIR}" ]
then
  echo ".kube dir ${KUBE_DIR} does not exist"
  exit 1
fi

docker pull "${CORD_IMG}"
DOCKER_CMD="docker run -id -e K8S_MASTER=${K8S_MASTER} \
       -e USER=${TEST_USER} \
       -v ${basepath}/docker_run.sh:/workspace/docker_run.sh \
       -v ${KUBE_DIR}:/workspace/.kube \
       ${CORD_IMG} /bin/bash"
if cont_id=$(eval "${DOCKER_CMD}")
then
  echo "Starting SIAB.robot in ${cont_id}"
  docker exec -ti "${cont_id}" /workspace/docker_run.sh
else
  echo "Failed to execute docker command ${cont_id}"
  exit 1
fi

