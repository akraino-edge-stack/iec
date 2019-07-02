#!/bin/bash -ex
# shellcheck disable=SC2016

#Modified from https://github.com/cachengo/seba_charts/blob/master/scripts/installSEBA.sh

basepath=$(cd "$(dirname "$0")"; pwd)
CORD_REPO=${CORD_REPO:-https://charts.opencord.org}
CORD_PLATFORM_VERSION=${CORD_PLATFORM_VERSION:-6.1.0}
SEBA_VERSION=${SEBA_VERSION:-1.0.0}
ATT_WORKFLOW_VERSION=${ATT_WORKFLOW_VERSION:-1.0.2}
CORD_CHART=${CORD_CHART:-${basepath}/../src_repo/seba_charts}

# TODO(alav): Make each step re-entrant

source util.sh

wait_for 10 'test $(kubectl get pods --all-namespaces | grep -ce "tiller.*Running") -eq 1'

# Add the CORD repository and update indexes

if [ "$(uname -m)" == "aarch64" ]; then
  if [ ! -d ${CORD_CHART}/cord-platform ]; then
    #git clone https://github.com/iecedge/seba_charts ${CORD_CHART}
    cd ${basepath}/../src_repo && git submodule update --init seba_charts
  fi
else
  helm repo add cord "${CORD_REPO}"
  helm repo update
  CORD_CHART=cord
fi


# Install the CORD platform
helm install -n cord-platform ${CORD_CHART}/cord-platform --version="${CORD_PLATFORM_VERSION}"
# Wait until 3 etcd CRDs are present in Kubernetes
wait_for 300 'test $(kubectl get crd | grep -ice etcd) -eq 3' || true

# Install the SEBA profile
helm install -n seba --version "${SEBA_VERSION}" ${CORD_CHART}/seba
wait_for 500 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1' || true

# Install the AT&T workflow
helm install -n att-workflow --version "${ATT_WORKFLOW_VERSION}" ${CORD_CHART}/att-workflow
wait_for 300 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1' || true

