#!/bin/bash -ex
# shellcheck disable=all

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

# Run ovnkube daemonsets for nodes
kubectl delete -f ${SCRIPTS_DIR}/yaml/ovnkube-node.yaml
sleep 3

# Run ovnkube-master daemonset.
kubectl delete -f ${SCRIPTS_DIR}/yaml/ovnkube-master.yaml
sleep 3


# Delete ovnkube-db daemonset.
kubectl delete -f ${SCRIPTS_DIR}/yaml/ovnkube-db.yaml
sleep 3

# Delete OVN namespace, service accounts, ovnkube-db headless service, configmap, and policies
kubectl delete -f ${SCRIPTS_DIR}/yaml/ovn-setup.yaml
sleep 2

#kubectl get pods -n ovn-kubernetes
