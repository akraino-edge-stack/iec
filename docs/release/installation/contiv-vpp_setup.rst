Contiv-VPP Setup
================

This document describes how to deployment IEC platform with Contiv-VPP
networking on bare metal hosts.The automatic deployment script provided
by IEC uses calico CNI by default. To enable Contiv-VPP network solution
for Kubernetes, you need to make some minor modifications.Now the IEC
only supports multiple NICs deployment, and does not support Configuring
STN for the time being.In addition, the deployment methods of IEC type1
and type2 are slightly different, and will be introduced in different
chapters.

Setting up for IEC type2
------------------------

IEC type2 deploy on large and powerful business servers.The main
installation steps as following:

Setting up DPDK
~~~~~~~~~~~~~~~

ALL port that are to be used by an DPDK aplication must be bound to the
uio_pci_generic, igb_uio or vfio-pci module before the application is
run, more detail info please refer `DPDK DOC`_.

The following guide will use vfio-pci. Load kernel module

::

    $ sudo modprobe vfio-pci

Verify that PCI driver has loaded successfully

::

    $ lsmod |grep pci
    vfio_pci               49152  0
    vfio_virqfd            16384  1 vfio_pci
    vfio_iommu_type1       24576  0
    vfio                   40960  2 vfio_iommu_type1,vfio_pci

Determining network adapter that vpp to use

::

    $ sudo lshw -class network -businfo
    Bus info          Device       Class      Description
    ================================================
    pci@0000:89:00.0  enp137s0f0   network    Ethernet Controller X710 for 10GbE SFP+
    pci@0000:89:00.1  enp137s0f1   network    Ethernet Controller X710 for 10GbE SFP+

In this example, enp137s0f1 used by vpp and binding to kernel module:

::

    $ sudo ~/dpdk/usertools/dpdk-devbind.py --bind=vfio-pci enp137s0f1

The script dpdk-devbind.py in `DPDK`_ repo.

Automation deployment
~~~~~~~~~~~~~~~~~~~~~

As a minimum requirement 3 nodes are needed: jumpserver, master node and
worker node. The two kinds nodes are configured by different script.

-  Modify default network solution

.. code:: diff

    --- a/src/foundation/scripts/config
    +++ b/src/foundation/scripts/config
    @@ -30,7 +30,7 @@ K8S_WORKER_GROUP=(
     CLUSTER_IP=172.16.1.136 # Align with the value in our K8s setup script
     POD_NETWORK_CIDR=192.168.0.0/16
     #IEC support three kinds network solution for Kubernetes: calico,flannel,contivpp
    -CNI_TYPE=calico
    +CNI_TYPE=contivpp
     #kubernetes-cni version 0.7.5/ 0.6.0
     CNI_VERSION=0.6.0

-  Master node configuration

Initialize DEV_NAME for master node,Instantiate the fourth argument of the setup-cni.sh script

.. code:: diff

    --- a/src/foundation/scripts/startup.sh
    +++ b/src/foundation/scripts/startup.sh
    @@ -99,7 +99,7 @@ deploy_k8s () {
       #Deploy etcd & CNI from master node
    -  SETUP_CNI="cd iec/src/foundation/scripts && source setup-cni.sh $CLUSTER_IP $POD_NETWORK_CIDR $CNI_TYPE"
    +  SETUP_CNI="cd iec/src/foundation/scripts && source setup-cni.sh $CLUSTER_IP $POD_NETWORK_CIDR $CNI_TYPE enp137s0f1"
       sshpass -p ${K8S_MASTERPW} ssh -o StrictHostKeyChecking=no ${HOST_USER}@${K8S_MASTER_IP} ${SETUP_CNI}
       SETUP_HELM="cd iec/src/foundation/scripts && source helm.sh"

The modified result is as follows

.. code:: diff

    --- a/src/foundation/scripts/setup-cni.sh
    +++ b/src/foundation/scripts/setup-cni.sh
    @@ -11,7 +11,7 @@ fi
     CLUSTER_IP=${1:-172.16.1.136} # Align with the value in our K8s setup script
     POD_NETWORK_CIDR=${2:-192.168.0.0/16}
     CNI_TYPE=${3:-calico}
    -DEV_NAME=${4:-}
    +DEV_NAME=${4:-enp137s0f1}

-  Worker node configuration

The same as master node, worker node need setting up DPDK and
determining network adapter. Initialize DEV_NAME for work node

.. code:: diff

    --- a/src/foundation/scripts/config
    +++ b/src/foundation/scripts/config
    @@ -42,4 +42,4 @@ KUBE_VERSION=1.13.0
     #  [10.169.40.106]="enp137s0f0"
     #  )
     declare -A DEV_NAME
    -DEV_NAME=()
    +DEV_NAME=([10.169.40.106]="enp137s0f0")

DEV_NAME is an associative array, list network interface device names
used by contivpp. Use IP address of K8S_WORKER_GROUP as key.

-  Launch setup

Simply start the installation script startup.sh on jumpserver:

::

    jenkins@jumpserver:~/iec/src/foundation/scripts$ ./startup.sh

for more details and information refer to `installation.instruction.rst`_

Setting up for IEC type1
------------------------

IEC type1 device is suitable for low power device. Now we choose
`MACCHIATObin`_ board as the main hardware
platform.

Install MUSDK
~~~~~~~~~~~~~

Marvell User-Space SDK(`MUSDK`_)
is a light-weight user-space I/O driver for Marvell's Embedded
Networking SoC's, more detail info please refer `VPP Marvell plugin`_

Automation deployment
~~~~~~~~~~~~~~~~~~~~~

-  Modify default yaml

.. code:: diff

    diff --git a/src/foundation/scripts/setup-cni.sh b/src/foundation/scripts/setup-cni.sh
    index d466831..6993006 100755
    --- a/src/foundation/scripts/setup-cni.sh
    +++ b/src/foundation/scripts/setup-cni.sh
    @@ -43,7 +43,7 @@ install_contivpp(){

       # Install contivpp CNI
       sed -i "s@10.1.0.0/16@${POD_NETWORK_CIDR}@" "${SCRIPTS_DIR}/cni/contivpp/contiv-vpp.yaml"
    -  kubectl apply -f "${SCRIPTS_DIR}/cni/contivpp/contiv-vpp.yaml"
    +  kubectl apply -f "${SCRIPTS_DIR}/cni/contivpp/contiv-vpp-macbin.yaml"
     }

-  Configuration

To configure a PP2 interface, MainVppInterface with the prefix mv-ppio-
must be configured in the NodeConfig section of the deployment yaml.
mv-ppio-X/Y is VPP interface name where X is PP2 device ID and Y is PPIO
ID Interface needs to be assigned to MUSDK in FDT configuration and
linux interface state must be up. Example configuration:

::

    ~/iec/src/foundation/scripts/cni/contivpp/contiv-vpp-macbin.yaml
        nodeConfig:
        - nodeName: net-arm-mcbin-iec
          mainVppInterface:
            interfaceName: mv-ppio-0/0
        - nodeName: net-arm-mcbin-iec-1
          mainVppInterface:
            interfaceName: mv-ppio-0/0

PP2 doesn't have any dependency on DPDK or DPDK plugin but it can work
with DPDK plugin enabled or disabled.It is observed that performace is
better around 30% when DPDK plugin is disabled. DPKD plugin can be
disabled by adding following config to the contiv-vswitch.conf.

.. code:: diff

    --- a/src/foundation/scripts/cni/contivpp/contiv-vswitch.conf
    +++ b/src/foundation/scripts/cni/contivpp/contiv-vswitch.conf
    @@ -24,3 +24,7 @@ socksvr {
     statseg {
        default
     }
    +plugins {
    +        plugin vpp_plugin.so { enable }
    +        plugin dpdk_plugin.so { disable }
    +}

-  Modify scripts

It`s necessary to modify relevant script as IEC type2 to support automatic deployment.

-  Launch setup

Simply start the installation script startup.sh on jumpserver:

::

    jenkins@jumpserver:~/iec/src/foundation/scripts$ ./startup.sh

for more details and information refer to
`installation.instruction.rst`_

Deployment Verification
-----------------------

invok ./src/foundation/scripts/nginx.sh install nginx; to test if CNI
enviroment is ready.

Uninstalling Contiv-VPP
-----------------------

To uninstall the network plugin for type2:

::

    kubectl delete -f  ./iec/src/foundation/scripts/cni/contivpp/contiv-vpp.yaml

To uninstall the network plugin for type1:

::

    kubectl delete -f  ./iec/src/foundation/scripts/cni/contivpp/contiv-vpp-macbin.yaml

In order to remove the persisted config, cleanup the bolt and ETCD
storage:

::

    rm -rf /var/etcd/contiv-data

.. All links go below this line
.. _`DPDK DOC`: https://doc.dpdk.org/guides/linux_gsg/linux_drivers.html#binding-and-unbinding-network-ports-to-from-the-kernel-modules
.. _`DPDK`: https://github.com/DPDK/dpdk/blob/main/usertools/dpdk-devbind.py
.. _`installation.instruction.rst`: ./installation.instruction.rst
.. _`MACCHIATObin`: https://www.solid-run.com/macchiatobin-gcp/
.. _`MUSDK`: https://github.com/MarvellEmbeddedProcessors/musdk-marvell
.. _`VPP Marvell plugin`: https://github.com/FDio/vpp/blob/master/src/plugins/marvell/README.rst
