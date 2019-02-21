#!/bin/bash
set -ex
echo "K8s Master IP is k8s_master_ip"
sudo sed -i -e 's/^\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\([\t ]\+\)\(k8s_slave_hostname.*$\)/k8s_slave_ip\2\3/g' /etc/hosts
apt update
apt install sshpass
pwd
git clone https://gerrit.akraino.org/r/iec
cd iec/scripts
./k8s_common.sh
joincmd=$(sshpass -p k8s_password ssh -o StrictHostKeyChecking=no k8s_user@k8s_master_ip 'for i in {1..300}; do if [ -f /home/ubuntu/joincmd ]; then break; else sleep 1; fi; done; cat /home/ubuntu/joincmd')
eval sudo $joincmd
