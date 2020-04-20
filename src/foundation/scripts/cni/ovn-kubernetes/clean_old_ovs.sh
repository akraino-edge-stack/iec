#!/bin/bash
set -o xtrace
set -e

not_clean=${1:-}

if [ -z ${not_clean} ] ; then
   # Clean the old openvswitch db info
   echo "Clean old ovs/ovn running dir ..."
   sudo rm -rf /var/lib/openvswitch
   sudo rm -rf /etc/ovn
   sudo rm -rf /var/run/ovn-kubernetes
   sudo rm -rf /etc/origin/openvswitch
fi
