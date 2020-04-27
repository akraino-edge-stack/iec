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

mkdir -p results
chmod 777 results

if ! [ -d "${KUBE_DIR}" ]
then
  echo ".kube dir ${KUBE_DIR} does not exist"
  exit 1
fi

docker pull "${CORD_IMG}"
DOCKER_CMD="docker run --rm -id \
       -e K8S_MASTER_IP=${K8S_MASTER_IP} \
       -e USER=${TEST_USER} \
       -v ${basepath}/docker_run.sh:/workspace/docker_run.sh \
       -v ${KUBE_DIR}:/workspace/.kube \
       -v ${PWD}/results:/workspace/results \
       ${CORD_IMG} \
       /bin/bash"
if cont_id=$(eval "${DOCKER_CMD}")
then
  echo "Starting SIAB.robot in ${cont_id}"
  docker exec "${cont_id}" sudo cp /workspace/docker_run.sh \
        "/home/${TEST_USER}/docker_run.sh"
  docker exec "${cont_id}" sudo chown "${TEST_USER}:${TEST_USER}" \
         "/home/${TEST_USER}/docker_run.sh"
  docker exec "${cont_id}" "/home/${TEST_USER}/docker_run.sh"
else
  echo "Failed to execute docker command ${cont_id}"
  exit 1
fi

