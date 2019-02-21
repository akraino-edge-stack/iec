#!/bin/sh

# shellcheck disable=SC2086

# set DPDK if available
has_dpdk=${has_dpdk:-"false"}

################################################################
# Stack parameters
base_img=${base_img:-"xenial"}
key_name=${key_name:-"ak-key"}
k8s_master_vol=${k8s_master_vol:-"k8s_master_vol"}
external_net=${external_net:-"external"}
k8s_user=${k8s_user:-"ubuntu"}
k8s_password=${k8s_password:-"ubuntu"}
has_dpdk_param=

floating_ip_param="--parameter public_ip_pool=$external_net"

if [ "$has_dpdk" = true ]; then
    has_dpdk_param="--parameter has_dpdk=true"
fi

################################################################

set -ex

retries=5

if [ -z "$OS_AUTH_URL" ]; then
    echo "OS_AUTH_URL not set; aborting"
    exit 1
fi

if ! [ -f ak-key.pem ]
then
  nova keypair-add "$key_name" > "$key_name".pem
  chmod 600 ak-key.pem
fi

skip_k8s_net=${skip_k8s_net:-}
skip_k8s_master=${skip_k8s_master:-}
skip_k8s_slaves=${skip_k8s_slaves:-}

stack_k8s_net=
stack_k8s_master=
stack_k8s_slaves=

case $1 in
start|stop)
    cmd=$1
    shift
    ;;
restart)
    shift
    tries=0
    while ! $0 stop "$@"; do
        tries=$((tries+1))
        if [ $tries -gt $retries ]; then
            echo "Unable to stop demo, exiting"
            exit 1
        fi
    done
    $0 start "$@"
    exit $?
    ;;
*)
    echo "Control script for managing a simple K8s cluster of VMs using Heat"
    echo "Available stacks:"
    echo "  - net - all the required networks and subnets"
    echo "  - k8s_master - K8s master VM"
    echo "  - k8s_slaves - configurable number of K8s slave VMs"
    echo "Use skip_<stack> to skip starting/stopping stacks, e.g."
    echo "#:~ > skip_k8s_net=1 ./$0 stop"
    echo "usage: $0 [start|stop] [k8s_net] [k8s_master] [k8s_slaves]"
    exit 1
    ;;
esac

if [ $# -gt 0 ]; then
    skip_k8s_net=1
    while [ $# -gt 0 ]; do
        eval unset skip_"$1"
        shift
    done
fi

# check OS status
tries=0
while ! openstack compute service list > /dev/null 2>&1; do
    tries=$((tries+1))
    if [ $tries -gt $retries ]; then
        echo "Unable to check Openstack health, exiting"
        exit 2
    fi
    sleep 5
done

for stack in $(openstack stack list -f value -c "Stack Name"); do
    echo "$stack" | grep -sq -e '^[a-zA-Z0-9_]*$' && eval stack_"$stack"=1
done

case $cmd in
start)
    if [ -z "$stack_k8s_net" ] && [ -z "$skip_k8s_net" ]; then
        echo "Starting k8s_net"
        openstack stack create --wait \
            --parameter external_net="$external_net" \
            -t k8s_net.yaml k8s_net
        # Might need to wait for the networks to become available
        # sleep 5
    fi

#    master_vol=$(openstack volume show $k8s_master_vol -f value -c id)
#            --parameter volume_id=$master_vol \

    k8s_master_ip=$(openstack stack output show k8s_net k8s_master_ip -f value -c output_value)
    k8s_pod_net_cidr=$(openstack stack output show k8s_net k8s_pod_net_cidr -f value -c output_value)
    k8s_svc_net_cidr=$(openstack stack output show k8s_net k8s_svc_net_cidr -f value -c output_value)
    k8s_cluster_ip=$(openstack stack output show k8s_net k8s_cluster_ip -f value -c output_value)
    if [ -z "$stack_k8s_master" ] && [ -z "$skip_k8s_master" ]; then
        echo "Starting Kubernetes master"
        openstack stack create --wait \
            --parameter key_name="$key_name" \
            --parameter k8s_master_ip="$k8s_master_ip" \
            --parameter k8s_pod_net_cidr="$k8s_pod_net_cidr" \
            --parameter k8s_svc_net_cidr="$k8s_svc_net_cidr" \
            --parameter k8s_cluster_ip="$k8s_cluster_ip" \
            --parameter k8s_user="$k8s_user" \
            --parameter k8s_password="$k8s_password" \
            $floating_ip_param \
            $has_dpdk_param \
            -t k8s_master.yaml k8s_master
    fi

    if [ -z "$stack_k8s_slaves" ] && [ -z "$skip_k8s_slaves" ]; then
        echo "Starting Kubernetes slaves"
        openstack stack create --wait \
            --parameter key_name="$key_name" \
            --parameter k8s_master_ip="$k8s_master_ip" \
            --parameter k8s_pod_net_cidr="$k8s_pod_net_cidr" \
            --parameter k8s_svc_net_cidr="$k8s_svc_net_cidr" \
            --parameter k8s_cluster_ip="$k8s_cluster_ip" \
            --parameter k8s_user="$k8s_user" \
            --parameter k8s_password="$k8s_password" \
            $floating_ip_param \
            $has_dpdk_param \
            -t k8s_slaves.yaml k8s_slaves
    fi

    openstack stack list
    ;;
stop)
    if [ -n "$stack_k8s_slaves" ] && [ -z "$skip_k8s_slaves" ]; then
        echo "Stopping Kubernetes slaves"
        openstack stack delete --yes --wait k8s_slaves
    fi

    if [ -n "$stack_k8s_master" ] && [ -z "$skip_k8s_master" ]; then
        echo "Stopping Kubernetes master"
        openstack stack delete --yes --wait k8s_master
    fi

    if [ -n "$stack_k8s_net" ] && [ -z "$skip_k8s_net" ]; then
        echo "Stopping k8s_net"
        openstack stack delete --yes --wait k8s_net
    fi

    openstack stack list
    ;;
esac
