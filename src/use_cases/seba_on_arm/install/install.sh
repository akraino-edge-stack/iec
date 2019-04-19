#!/bin/bash -ex
# shellcheck disable=SC2016

#Modified from https://github.com/cachengo/seba_charts/blob/master/scripts/installSEBA.sh

# shellcheck disable=SC2046
basepath=$(cd `dirname $0`; pwd)
CORD_REPO=${CORD_REPO:-https://charts.opencord.org}
CORD_PLATFORM_VERSION=${CORD_PLATFORM_VERSION:-6.1.0}
SEBA_VERSION=${SEBA_VERSION:-1.0.0}
ATT_WORKFLOW_VERSION=${ATT_WORKFLOW_VERSION:-1.0.2}

CORD_CHART=${CORD_CHART:-${basepath}/../src_repo/seba_charts}

# TODO(alav): Make each step re-entrant

function wait_for {
  # Execute in a subshell to prevent local variable override during recursion
  (
    local total_attempts=$1; shift
    local cmdstr=$*
    local sleep_time=2
    echo -e "\n[wait_for] Waiting for cmd to return success: ${cmdstr}"
    # shellcheck disable=SC2034
    for attempt in $(seq "${total_attempts}"); do
      echo "[wait_for] Attempt ${attempt}/${total_attempts%.*} for: ${cmdstr}"
      # shellcheck disable=SC2015
      eval "${cmdstr}" && echo "[wait_for] OK: ${cmdstr}" && return 0 || true
      sleep "${sleep_time}"
    done
    echo "[wait_for] ERROR: Failed after max attempts: ${cmdstr}"
    return 1
  )
}

wait_for 10 'test $(kubectl get pods --all-namespaces | grep -ce "tiller.*Running") -eq 1'

# Add the CORD repository and update indexes

if [ "$(uname -m)" == "aarch64" ]; then
  if [ ! -d ${CORD_CHART}/cord-platform ]; then
    #git clone https://github.com/iecedge/seba_charts ${CORD_CHART}
    cd ${basepath}/../src_repo && git submodule update seba_charts
  fi
else
  helm repo add cord "${CORD_REPO}"
  helm repo update
  CORD_CHART=cord
fi


# Install the CORD platform
helm install -n cord-platform ${CORD_CHART}/cord-platform --version="${CORD_PLATFORM_VERSION}"
# Wait until 3 etcd CRDs are present in Kubernetes
wait_for 300 'test $(kubectl get crd | grep -ice etcd) -eq 3'

# Install the SEBA profile
helm install -n seba --version "${SEBA_VERSION}" ${CORD_CHART}/seba
wait_for 1500 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1'

# Install the AT&T workflow
helm install -n att-workflow --version "${ATT_WORKFLOW_VERSION}" ${CORD_CHART}/att-workflow
wait_for 300 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|tosca-loader.*Completed)") -eq 1'
