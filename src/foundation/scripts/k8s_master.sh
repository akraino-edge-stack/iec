#!/bin/bash -ex
# shellcheck source=/dev/null

# For host setup as Kubernetes master
# Use the src of the default route as the default local IP
DEF_SRC_IP=$(ip route get 8.8.8.8 | awk '{ for (nn=1;nn<=NF;nn++) if ($nn~"src") print $(nn+1) }')
MGMT_IP=${1:-${DEF_SRC_IP}}
MGMT_HOST=$(nslookup $MGMT_IP | grep "in-addr.arpa" | cut -d " " -f 3 | awk '{ print substr( $0, 1, length($0)-1 ) }')  || true
#MGMT_HOST=$(nslookup $MGMT_IP | grep "in-addr.arpa" | cut -d " " -f 3 | sed 's/.$//') || true
echo $MGMT_HOST

POD_NETWORK_CIDR=${2:-192.168.0.0/16}
SERVICE_CIDR=${3:-172.16.1.0/24}

if [ -z "${MGMT_IP}" ]; then
  echo "Please specify a management IP!"
  exit 1
fi

if [ -z "${MGMT_HOST}" ]; then
  echo "MGMT HOST is not set, using MGMT_IP instead."
  MGMT_HOST=$MGMT_IP
fi

if ! kubectl get nodes --request-timeout=3s; then
  sudo kubeadm config images pull
  #sudo kubeadm init \
  #  --pod-network-cidr="${POD_NETWORK_CIDR}" \
  #  --apiserver-advertise-address="${MGMT_IP}" \
  #  --service-cidr="${SERVICE_CIDR}"
  sudo kubeadm init \
    --pod-network-cidr="${POD_NETWORK_CIDR}" \
    --apiserver-advertise-address="${MGMT_HOST}" \
    --service-cidr="${SERVICE_CIDR}"

  if [ "$(id -u)" = 0 ]; then
    echo "export KUBECONFIG=/etc/kubernetes/admin.conf" | \
      tee -a "${HOME}/.bashrc"
    # shellcheck disable=SC1090
    source "${HOME}/.bashrc"
  fi

  mkdir -p "${HOME}/.kube"
  # shellcheck disable=SC2216
  yes | sudo cp -rf /etc/kubernetes/admin.conf "${HOME}/.kube/config"
  sudo chown "$(id -u)":"$(id -g)" "${HOME}/.kube/config"

  sleep 5
  sudo swapon -a
fi
