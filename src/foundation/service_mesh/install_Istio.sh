#!/bin/bash
set -x

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


for i in Istio/init/crd*yaml; do kubectl apply -f $i; done

kubectl apply -f Istio/istio-demo-arm64.yaml

# Waiting for Istio ready
wait_for 100 'test $(kubectl get pods -n istio-system | grep -ce "Running") -eq 12'

#Apply the following ConfigMap to enable injection of Dikastes alongside Envoy.(injection ConfigMap)
kubectl apply -f Istio/istio-inject-configmap-1.1.7.yaml

#Enable the default namespace auto inject
kubectl label namespace default istio-injection=enabled --overwrite
kubectl get namespace -L istio-injection
