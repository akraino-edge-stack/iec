#!/bin/bash -ex

VERSION='v2.12.3'
TILLER_SA_RBAC=~/tiller-rbac.yaml
if [ "$(uname -m)" == 'aarch64' ]; then
  FLAVOR='linux-arm64'
else
  FLAVOR='linux-amd64'
fi

URI_ROOT='https://storage.googleapis.com/kubernetes-helm'
TGZ_NAME="helm-${VERSION}-${FLAVOR}.tar.gz"

if [ ! -e /usr/bin/helm ] || [ ! -e /usr/bin/tiller ]; then
  wget -O "/tmp/${TGZ_NAME}" "${URI_ROOT}/${TGZ_NAME}"
  sudo tar xpPf "/tmp/${TGZ_NAME}" --overwrite \
    --transform "s|${FLAVOR}|/usr/bin|" "${FLAVOR}/"{helm,tiller}
  rm -f "/tmp/${TGZ_NAME}"
fi

if ! kubectl get serviceaccounts --namespace=kube-system | grep -q tiller; then
  cat <<EOF > "${TILLER_SA_RBAC}"
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
EOF
  kubectl create -f "${TILLER_SA_RBAC}"
  helm init --service-account tiller --tiller-image="jessestuart/tiller:${VERSION}"
fi
