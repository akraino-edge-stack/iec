#!/bin/bash -ex
# shellcheck disable=SC2016

#Modified from https://github.com/cachengo/seba_charts/blob/master/scripts/mini_test.sh

basepath=$(cd "$(dirname "$0")"; pwd)
BBSIM_VERSION=${BBSIM_VERSION:-1.0.0}
CORD_CHART=${CORD_CHART:-${basepath}/../../src_repo/seba_charts}

source ${basepath}/../util.sh

# Install bbsim
helm install -n bbsim --version ${BBSIM_VERSION} ${CORD_CHART}/bbsim
wait_for 300 'test $(kubectl get pods | grep -vcE "(\s(.+)/\2.*Running|bbsim.*Running)") -eq 1' || true

TOSCA_POD=`kubectl get pods | grep xos-tosca | cut -d " " -f1`
TOSCA_IP=`kubectl describe pod $TOSCA_POD | grep Node: | cut -d "/" -f2`
BBSIM_IP=`kubectl get services -n voltha | grep bbsim | tr -s ' ' | cut -d " " -f3`


# Create the first model
curl \
  -H "xos-username: admin@opencord.org" \
  -H "xos-password: letmein" \
  -X POST \
  --data-binary @fabric.yaml \
  http://$TOSCA_IP:30007/run

# Create the second model
sed "s/{{bbsim_ip}}/$BBSIM_IP/g" olt.yaml > olt.yaml.tmp
curl \
  -H "xos-username: admin@opencord.org" \
  -H "xos-password: letmein" \
  -X POST \
  --data-binary @olt.yaml.tmp \
  http://$TOSCA_IP:30007/run
rm olt.yaml.tmp
