#!/bin/bash
# shellcheck disable=SC1073,SC1072,SC1039,SC2059,SC2046
set -x

kubectl delete -f sriov-crd.yaml
sleep 2
kubectl delete -f calico-daemonset.yaml
#kubectl delete -f calico-daemonset-k8s-v1.16.yaml
sleep 5
#kubectl delete -f multus-sriov-calico-daemonsets.yaml
kubectl delete -f multus-sriov-calico-daemonsets-k8s-v1.16.yaml
sleep 5
kubectl delete -f configMap.yaml
sleep 2

kubectl get node $(hostname) -o json | jq '.status.allocatable' || true
kubectl get pods --all-namespaces
