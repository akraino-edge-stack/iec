#!/bin/bash
# shellcheck disable=SC1073,SC1072,SC1039,SC2059,SC2046
set -x

kubectl delete -f sriov-crd.yaml
sleep 2
kubectl delete -f sriov-cni-daemonset.yaml
sleep 2
kubectl delete -f calico.yaml
sleep 5

kubectl delete -f sriovdp-daemonset.yaml
sleep 2
kubectl delete -f multus-daemonset.yml
sleep 2

kubectl delete -f configMap.yaml
sleep 2

kubectl get node $(hostname) -o json | jq '.status.allocatable' || true
kubectl get pods --all-namespaces
