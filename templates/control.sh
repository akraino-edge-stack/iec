#!/bin/sh

# set DPDK if available
# has_dpdk=true

################################################################
# Stack parameters
base_img="xenial"
key_name="ak-key"
k8_master_vol="k8_master_vol"
external_net="admin_floating_net"
slave_count="2"

floating_ip_param="--parameter public_ip_pool=$external_net"

if [ "$has_dpdk" = true ]; then
    has_dpdk_param="--parameter has_dpdk=true"
fi

################################################################

set -e
set -x

if [ -z "$OS_AUTH_URL" ]; then
    . $HOME/openrc
fi

if ! [ -f ak-key.pem ]
then
  nova keypair-add $key_name > $key_name.pem
  chmod 600 ak-key.pem
fi

skip_img=1
#keep_img=1
#skip_net=1
#skip_k8_master=1
#skip_k8_slave=1

case $1 in
start|stop)
    cmd=$1
    shift
    ;;
restart)
    shift
    tries=0
    while ! $0 stop $*; do
        tries=$((tries+1))
        if [ $tries -gt 5 ]; then
            echo "Unable to stop demo, exiting"
            exit 1
        fi
    done
    $0 start $*
    exit $?
    ;;
*)
    echo "usage: $0 [start|stop] [img] [net] [k8_master] "
    exit 1
    ;;
esac

if [ $# -gt 0 ]; then
    skip_net=1
    while [ $# -gt 0 ]; do
        eval unset skip_$1
        shift
    done
fi

# check OS status
tries=0
while ! openstack compute service list > /dev/null 2>&1; do
    tries=$((tries+1))
    if [ $tries -gt 6 ]; then
        echo "Unable to check Openstack health, exiting"
        exit 2
    fi
    sleep 20
done

for stack in $(openstack stack list -f value -c "Stack Name"); do
    echo "$stack" | grep -sq -e '^[a-zA-Z0-9_]*$' && eval stack_$stack=1
done

case $cmd in
start)
    if [ -z "$stack_img" -a -z "$skip_img" ]; then
        echo "Starting img"
        openstack stack create --wait \
            --parameter base_img=$base_img \
            --parameter slave_count=$slave_count \
            --parameter k8_master_vol=$k8_master_vol \
            -t img.yaml img
    fi

    if [ -z "$stack_net" -a -z "$skip_net" ]; then
        echo "Starting net"
        openstack stack create --wait \
            --parameter external_net=$external_net \
            -t net.yaml net
    fi

#    master_vol=$(openstack volume show $k8_master_vol -f value -c id)
#            --parameter volume_id=$master_vol \

    k8_master_ip=$(openstack stack output show net k8_master_ip -f value -c output_value)
    k8_pod_net_cidr=$(openstack stack output show net k8_pod_net_cidr -f value -c output_value)
    k8_svc_net_cidr=$(openstack stack output show net k8_svc_net_cidr -f value -c output_value)
    k8_cluster_ip=$(openstack stack output show net k8_cluster_ip -f value -c output_value)
    if [ -z "$stack_k8_master" -a -z "$skip_k8_master"  ]; then
        echo "Starting Kubernetes master"
        openstack stack create --wait \
            --parameter key_name=$key_name \
            --parameter k8_master_ip=$k8_master_ip \
            --parameter k8_pod_net_cidr=$k8_pod_net_cidr \
            --parameter k8_svc_net_cidr=$k8_svc_net_cidr \
            --parameter k8_cluster_ip=$k8_cluster_ip \
            $floating_ip_param \
            $has_dpdk_param \
            -t k8_master.yaml k8_master
    fi

    if [ -z "$stack_k8_slave" -a -z "$skip_k8_slave"  ]; then
        echo "Starting Kubernetes slave"
        openstack stack create --wait \
            --parameter key_name=$key_name \
            --parameter slave_count=$slave_count \
            --parameter k8_master_ip=$k8_master_ip \
            --parameter k8_pod_net_cidr=$k8_pod_net_cidr \
            --parameter k8_svc_net_cidr=$k8_svc_net_cidr \
            --parameter k8_cluster_ip=$k8_cluster_ip \
            $floating_ip_param \
            $has_dpdk_param \
            -t k8_slave.yaml k8_slave
    fi

    openstack stack list
    ;;
stop)
    if [ -n "$stack_k8_slave" -a -z "$skip_k8_slave" ]; then
        echo "Stopping Kubernetes slave"
        openstack stack delete --yes --wait k8_slave
    fi

    if [ -n "$stack_k8_master" -a -z "$skip_k8_master" ]; then
        echo "Stopping Kubernetes master"
        openstack stack delete --yes --wait k8_master
    fi

    if [ -n "$stack_net" -a -z "$skip_net" ]; then
        echo "Stopping net"
        openstack stack delete --yes --wait net
    fi

    if [ -n "$stack_img" -a -z "$skip_img" -a \
         ! -n "$keep_img" -o ! -z "$keep_img" ]; then
        echo "Stopping img"
        openstack stack delete --yes --wait img
    fi
    openstack stack list
    ;;
esac
