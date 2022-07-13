#!/bin/bash

set -x

WORKDIR=$(pwd)
TMP_DIR=$(mktemp -d)
CALICO_VERSION=${1:-3.23.1}

MARCH=$(uname -m)

if [ $MARCH == "aarch64" ]; then ARCH=arm64;
elif [ $MARCH == "x86_64" ]; then ARCH=amd64;
else ARCH="unknown";
fi

echo ARCH=$ARCH

echo "Restore kube-proxy:"
kubectl patch ds -n kube-system kube-proxy --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": null}}}}}'

if [ ! -f /usr/local/bin/calicoctl ]; then
   curl -L https://github.com/projectcalico/calico/releases/download/v${CALICO_VERSION}/calicoctl-linux-${ARCH} -o ${WORKDIR}/calicoctl;
   chmod +x ${WORKDIR}/calicoctl;
   sudo cp ${WORKDIR}/calicoctl /usr/local/bin;
fi

echo "Restore eBPF mode:"
calicoctl patch felixconfiguration default --patch='{"spec": {"bpfEnabled": false}}'

echo "Disable Direct Server Return(DSR) mode: optional"
calicoctl patch felixconfiguration default --patch='{"spec": {"bpfExternalServiceMode": "Tunnel"}}'

