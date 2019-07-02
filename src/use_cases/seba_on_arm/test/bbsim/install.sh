#!/bin/bash -ex
# shellcheck disable=SC2016

basepath=$(cd "$(dirname "$0")"; pwd)
BBSIM_VERSION=${BBSIM_VERSION:-1.0.0}
CORD_CHART=${CORD_CHART:-${basepath}/../../src_repo/seba_charts}

source ${basepath}/../util.sh

# Install bbsim
helm install -n bbsim --version ${BBSIM_VERSION} ${CORD_CHART}/bbsim
wait_for 300 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|bbsim.*Running)") -eq 1' || true
