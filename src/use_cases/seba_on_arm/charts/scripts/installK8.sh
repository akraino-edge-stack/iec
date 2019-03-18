curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add
echo 'echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" >>/etc/apt/sources.list.d/kubernetes.list' | sudo -s
apt-get update
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    build-essential \
    docker.io \
    kubelet \
    kubeadm \
    kubectl
swapoff -a
