#!/bin/bash -ex

VERSION='v2.12.3'
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
