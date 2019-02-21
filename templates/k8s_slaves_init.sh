#!/bin/bash
set -x
echo "K8s Master IP is k8_master_ip"
apt update
apt install sshpass
pwd
git clone https://gerrit.akraino.org/r/iec
cd iec/scripts
./k8s_common.sh
joincmd=$(sshpass -p k8s_password ssh -o StrictHostKeyChecking=no k8s_user@k8_master_ip 'for i in {1..300}; do if [ -f /home/ubuntu/joincmd ]; then break; else sleep 1; fi; done; cat /home/ubuntu/joincmd')
eval sudo $joincmd
