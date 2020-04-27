#!/bin/bash
##############################################################################
# Copyright (c) 2020 Akraino IEC Team.
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

set -ex

basepath=$(cd "$(dirname "$0")"; pwd)

CORD_IMG="${CORD_IMG:-iecedge/cord-tester:cord-7.0}"
KUBE_DIR="${KUBE_DIR:-${PWD}/.kube}"
K8S_MASTER_IP="${K8S_MASTER_IP:-127.0.0.1}"
TEST_USER="${TEST_USER:-ubuntu}"

rm -rf results
mkdir -m 777 results

trap f_clean EXIT

f_clean(){
  echo "Execution finished, cleaning up"
  chmod -R 777 results
}

if ! [ -d "${KUBE_DIR}" ]
then
  echo ".kube dir ${KUBE_DIR} does not exist"
  exit 1
fi

docker pull "${CORD_IMG}"
docker run --rm -it \
    -e K8S_MASTER_IP=${K8S_MASTER_IP} \
    -e USER=${TEST_USER} \
    -v ${basepath}/docker_run.sh:/workspace/docker_run.sh \
    -v ${KUBE_DIR}:/workspace/.kube \
    -v ${PWD}/results:/workspace/results \
    ${CORD_IMG} \
    /workspace/docker_run.sh

