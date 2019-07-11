#!/bin/bash

set -ex

CORD_REPO="${CORD_REPO:-https://github.com/opencord/cord-tester.git}"
CORD_REV="cord-6.1"
VOLTHA_REPO="${VOLTHA_REPO:-https://github.com/opencord/voltha.git}"
VOLTHA_REV="master"
K8S_MASTER="${K8S_MASTER:-127.0.0.1}"
KUBE_DIR="${KUBE_DIR:-/workspace/.kube}"
USER="${USER:-ubuntu}"

# The ssh server must be running since cord-tester tries to connect
# to localhost
sudo /etc/init.d/ssh restart
cd $HOME
cp -r "${KUBE_DIR}" .kube
sudo chown -R $(id -u):$(id -g) .kube

git clone "${CORD_REPO}" cord-tester && cd cord-tester && \
    git checkout "${CORD_REV}" && cd ../
git clone "${VOLTHA_REPO}" voltha && cd voltha && \
    git checkout "${VOLTHA_REV}" && cd ../

cd cord-tester/src/test/cord-api
./setup_venv.sh
source venv-cord-tester/bin/activate
# As per documentation, we set the SERVER_IP before anything
sed -i "s/SERVER_IP.*=.*'/SERVER_IP = '172.16.10.36'/g" \
     Properties/RestApiProperties.py
cd Tests/WorkflowValidations/

export SERVER_IP="${K8S_MASTER}"

robot -v ONU_STATE_VAR:onu_state --removekeywords wuks -e notready \
      -i stable -v "VOLTHA_DIR:${HOME}/voltha" SIAB.robot
