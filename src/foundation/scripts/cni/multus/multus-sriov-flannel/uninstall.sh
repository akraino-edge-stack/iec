#!/bin/bash -ex
# shellcheck disable=SC1073,SC1072,SC1039,SC2059,SC2046


kubectl delete -f sriov-crd.yaml
sleep 2
kubectl delete -f flannel-daemonset.yml
sleep 5
kubectl delete -f multus-sriov-flannel-daemonsets.yaml
sleep 5
kubectl delete -f configMap.yaml
sleep 2

kubectl get node $(hostname) -o json | jq '.status.allocatable'
