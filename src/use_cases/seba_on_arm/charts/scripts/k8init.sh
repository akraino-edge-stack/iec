

if [ "$(uname -m)" == 'aarch64' ]; then
  ARCH=arm64
  ETCD_IMAGE=quay.io/coreos/etcd:v3.3.9-arm64
  UNSUPPORTED_ARCH=arm64
else
  ARCH=amd64
  ETCD_IMAGE=quay.io/coreos/etcd:v3.3.9
fi

# Start Kubernetes
sysctl net.bridge.bridge-nf-call-iptables=1
kubeadm init \
  --pod-network-cidr=192.168.0.0/16
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Taint the master node
kubectl taint nodes --all node-role.kubernetes.io/master-

# Set up Calico
sed "s;{{etcd_image}};$ETCD_IMAGE;g" etcd.yaml > etcd.yaml.tmp
sed -i "s/{{unsupported_arch}}/$UNSUPPORTED_ARCH/g" etcd.yaml.tmp
kubectl apply -f etcd.yaml.tmp
kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/rbac.yaml
kubectl apply -f calico.yaml
rm *.tmp

# Setup helm
wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-$ARCH.tar.gz
tar -xvf helm-v2.12.3-linux-$ARCH.tar.gz
cp linux-$ARCH/helm /usr/bin
cp linux-$ARCH/tiller /usr/bin
if [ $ARCH == 'arm64' ]; then
  helm init --tiller-image=jessestuart/tiller:v2.9.1
else
  helm init
fi
kubectl create serviceaccount --namespace kube-system tiller
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
