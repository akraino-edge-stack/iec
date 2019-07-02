#!/bin/bash -ex
# shellcheck disable=SC2016

TOSCA_POD=$(kubectl get pods | grep xos-tosca | cut -d " " -f1)
TOSCA_IP=$(kubectl describe pod "$TOSCA_POD" | grep Node: | cut -d "/" -f2)
BBSIM_IP=$(kubectl get services -n voltha | grep bbsim | tr -s ' ' | cut -d " " -f3)


# Create the first model
curl \
  -H "xos-username: admin@opencord.org" \
  -H "xos-password: letmein" \
  -X POST \
  --data-binary @fabric.yaml \
  "http://$TOSCA_IP:30007/run"

# Create the second model
sed "s/{{bbsim_ip}}/$BBSIM_IP/g" olt.yaml > olt.yaml.tmp
curl \
  -H "xos-username: admin@opencord.org" \
  -H "xos-password: letmein" \
  -X POST \
  --data-binary @olt.yaml.tmp \
  "http://$TOSCA_IP:30007/run"
rm olt.yaml.tmp
