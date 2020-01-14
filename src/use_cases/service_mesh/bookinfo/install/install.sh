#!/bin/bash -ex
# shellcheck disable=SC2016
# shellcheck source=/dev/null

NODE_IP=${1:-10.169.36.152}

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

# Enable default namespace as auto-inject mode
# kubectl label namespace default istio-injection=enabled

basepath=$(cd "$(dirname "$0")"; pwd)
INFO_YAML=${INFO_YAML:-${basepath}/../config}

# TODO(alav): Make each step re-entrant

# shellcheck source=/dev/null
# Waiting for Istio ready
wait_for 100 'test $(kubectl get pods -n istio-system | grep -ce "Running") -eq 12'

# Start bookinfo pods
kubectl apply -f $INFO_YAML/bookinfo.yaml

# Waiting for sample case ready
wait_for 100 'test $(kubectl get pods | grep -ce "Running") -eq 6'

# Start gateway
kubectl apply -f $INFO_YAML/bookinfo-gateway.yaml

# Configure gate way
INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].nodePort}')
SECURE_INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="https")].nodePort}')
export GATEWAY_URL=$NODE_IP:$INGRESS_PORT

# Confirm the result
curl -s http://${GATEWAY_URL}/productpage | grep -o "<title>.*</title>"
