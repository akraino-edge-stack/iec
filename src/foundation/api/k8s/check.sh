#!/bin/bash -ex
svcip=$(kubectl get services iec-apiserver-svc  -o json | grep clusterIP | cut -f4 -d'"')
sleep 1
wget -O /dev/null "http://$svcip"
wget -O /dev/null "http://$svcip/v1/iec/status"
