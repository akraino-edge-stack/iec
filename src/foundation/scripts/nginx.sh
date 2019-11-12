#!/bin/bash -ex

NGINX_APP=~/nginx-app.yaml

cat <<EOF > "${NGINX_APP}"
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  type: NodePort
  ports:
  - port: 80
    protocol: TCP
    name: http
  selector:
    app: nginx
---
apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
spec:
  replicas: 2
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
EOF

if [ -f "$HOME/.bashrc" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.bashrc"
fi

if ! kubectl get services | grep -q nginx; then
  kubectl create -f "${NGINX_APP}"
fi
kubectl get nodes
kubectl get services
kubectl get pods
kubectl get rc

attempts=60
while [ $attempts -gt 0 ]
do
  if [ 3 == "$(kubectl get pods | grep -c -e STATUS -e Running)" ]; then
    break
  fi
  ((attempts-=1))
  sleep 10
done
[ $attempts -gt 0 ] || exit 1

svcip=$(kubectl get services nginx  -o json | grep clusterIP | cut -f4 -d'"')
sleep 20
wget -O /dev/null "http://$svcip"
kubectl delete -f "${NGINX_APP}"
rm -f "${NGINX_APP}"
kubectl get rc
kubectl get pods
kubectl get services
