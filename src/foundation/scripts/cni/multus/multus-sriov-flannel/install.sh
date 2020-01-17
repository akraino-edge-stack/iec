#!/bin/bash -ex
# shellcheck disable=SC2016,SC2046

#SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

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


kubectl create -f configMap.yaml
wait_for 5 'test $(kubectl get configmap -n kube-system | grep sriovdp-config -c ) -eq 1'

kubectl create -f multus-sriov-flannel-daemonsets.yaml
wait_for 100 'test $(kubectl get pods -n kube-system | grep -e "kube-multus-ds" | grep "Running" -c) -ge 1'
wait_for 20 'test $(kubectl get pods -n kube-system | grep -e "kube-sriov-cni" | grep "Running" -c) -ge 1'
wait_for 20 'test $(kubectl get pods -n kube-system | grep -e "kube-sriov-device-plugin" | grep "Running" -c) -ge 1'

kubectl create -f flannel-daemonset.yml
wait_for 100 'test $(kubectl get pods -n kube-system | grep -e "kube-flannel-ds" | grep "Running" -c) -ge 1'

kubectl create -f sriov-crd.yaml
wait_for 5 'test $(kubectl get crd | grep -e "network-attachment-definitions" -c) -ge 1'


kubectl get node $(hostname) -o json | jq '.status.allocatable'
