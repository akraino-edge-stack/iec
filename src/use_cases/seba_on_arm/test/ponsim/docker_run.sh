#!/bin/bash

set -ex

CORD_REPO="${CORD_REPO:-https://github.com/opencord/cord-tester.git}"
CORD_REV="cord-6.1"
VOLTHA_REPO="${VOLTHA_REPO:-https://github.com/opencord/voltha.git}"
VOLTHA_REV="master"
K8S_MASTER_IP="${K8S_MASTER_IP:-127.0.0.1}"
KUBE_DIR="${KUBE_DIR:-/workspace/.kube}"
USER="${USER:-ubuntu}"

# The ssh server must be running since cord-tester tries to connect
# to localhost
sudo /etc/init.d/ssh restart
cd "${HOME}"
cp -r "${KUBE_DIR}" .kube
sudo chown -R "$(id -u)":"$(id -g)" .kube

git clone "${CORD_REPO}" cord-tester -b "${CORD_REV}"
git clone "${VOLTHA_REPO}" voltha -b "${VOLTHA_REV}"

cd cord-tester/src/test/cord-api
./setup_venv.sh
# shellcheck disable=SC1091
source venv-cord-tester/bin/activate
# As per documentation, we set the SERVER_IP before anything
sed -i "s/SERVER_IP.*=.*'/SERVER_IP = '172.16.10.36'/g" \
     Properties/RestApiProperties.py
cd Tests/WorkflowValidations/

export SERVER_IP="${K8S_MASTER}"

robot -v ONU_STATE_VAR:onu_state --removekeywords wuks -e notready \
      -i stable -v "VOLTHA_DIR:${HOME}/voltha" SIAB.robot
