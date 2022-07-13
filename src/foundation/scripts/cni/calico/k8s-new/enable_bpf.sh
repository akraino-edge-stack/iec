#!/bin/bash

set -x

WORKDIR=$(pwd)
TMP_DIR=$(mktemp -d)
MARCH=$(uname -m)
CALICO_VERSION=${1:-3.23.1}

if [ $MARCH == "aarch64" ]; then ARCH=arm64;
elif [ $MARCH == "x86_64" ]; then ARCH=amd64;
else ARCH="unknown";
fi
echo ARCH=$ARCH

k8s_ep=$(kubectl get endpoints kubernetes -o wide | grep kubernetes | cut -d " " -f 4)
k8s_host=$(echo $k8s_ep | cut -d ":" -f 1)
k8s_port=$(echo $k8s_ep | cut -d ":" -f 2)


cat <<EOF > ${WORKDIR}/k8s_service.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: kube-system
data:
  KUBERNETES_SERVICE_HOST: "__KUBERNETES_SERVICE_HOST__"
  KUBERNETES_SERVICE_PORT: "__KUBERNETES_SERVICE_PORT__"
EOF


sed -i "s/__KUBERNETES_SERVICE_HOST__/${k8s_host}/" ${WORKDIR}/k8s_service.yaml
sed -i "s/__KUBERNETES_SERVICE_PORT__/${k8s_port}/" ${WORKDIR}/k8s_service.yaml

kubectl apply -f ${WORKDIR}/k8s_service.yaml

echo "Disable kube-proxy:"
kubectl patch ds -n kube-system kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"non-calico": "true"}}}}}'

if [ ! -f /usr/local/bin/calicoctl ]; then
   echo "No calicoctl, install now:"
   curl -L https://github.com/projectcalico/calico/releases/download/v${CALICO_VERSION}/calicoctl-linux-${ARCH} -o ${WORKDIR}/calicoctl;
   chmod +x ${WORKDIR}/calicoctl;
   sudo cp ${WORKDIR}/calicoctl /usr/local/bin;
   rm ${WORKDIR}/calicoctl
fi

echo "Enable eBPF:"
calicoctl patch felixconfiguration default --patch='{"spec": {"bpfEnabled": true}}'

echo "Enable Direct Server Return(DSR) mode: optional"
calicoctl patch felixconfiguration default --patch='{"spec": {"bpfExternalServiceMode": "DSR"}}'
