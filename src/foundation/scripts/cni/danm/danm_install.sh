#!/bin/bash
set -o xtrace
set -e

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

if [ "$(uname -m)" == 'aarch64' ]; then
  ARCH='arm64'
else
  ARCH='amd64'
fi

echo "SCRIPTS_DIR is :$SCRIPTS_DIR"

# Get binary
wget -P ${SCRIPTS_DIR} "https://github.com/iecedge/danm-binary/releases/download/v4.0.0/danm-${ARCH}" -O danm
wget -P ${SCRIPTS_DIR} "https://github.com/iecedge/danm-binary/releases/download/v4.0.0/fakeipam-${ARCH}" -O fakeipam
chmod +x ${SCRIPTS_DIR}/danm ${SCRIPTS_DIR}/fakeipam

# Copy binary into CNI plugin directory
cp -f ${SCRIPTS_DIR}/danm /opt/cni/bin
cp -f ${SCRIPTS_DIR}/fakeipam /opt/cni/bin

# Put DANM config file into CNI configuration directory
cp -f ${SCRIPTS_DIR}/00-danm.conf /etc/cni/net.d/
