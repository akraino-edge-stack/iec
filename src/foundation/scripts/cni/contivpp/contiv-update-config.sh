#!/bin/bash
set -o xtrace
set -e

SCRIPTS_DIR=$(dirname "${BASH_SOURCE[0]}")

echo "SCRIPTS_DIR is :$SCRIPTS_DIR"

DEV_NAME=${1:-}

if [ -z "${DEV_NAME}" ]
then
  echo "Please specify a device name!"
  exit 1
fi

# Extract PCI address
PCI_ADDRESS=$(lshw -class network -businfo | awk -F '@| ' '/pci.*'$DEV_NAME'/ {printf $2}')
if [ -z "${PCI_ADDRESS}" ]
then
  echo "PCI_ADDRESS is NULL, maybe $DEV_NAME is wrong!"
  exit 1
fi

# Update config file
mkdir -p /etc/vpp
cp -f ${SCRIPTS_DIR}/contiv-vswitch.conf  /etc/vpp/contiv-vswitch.conf
cat <<EOF >> /etc/vpp/contiv-vswitch.conf
dpdk {
    dev $PCI_ADDRESS
}
EOF

# make sure that the selected interface is shut down, otherwise VPP would not grab it
ifconfig $DEV_NAME down
