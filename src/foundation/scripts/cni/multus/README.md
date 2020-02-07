# Multus/SRIOV CNI&Device Plugin Support for IEC


## Introduction
This commit provides Kubernetes networking support for Multus with SRIOV CNI support both on arm64 and amd64. A special configuration file for Broadcom smartNIC Stingray PS225 is provided as an example. So it can not only be used as a sample container networking support for Stingray PS225 with its sriov interfaces, but also a generic SRIOV support for various ethernet NICs.
Here we would like to provide 2 types legacy CNIs besides the SRIOV-CNI by Multus, which are [Flannel](https://coreos.com/flannel/docs/latest/kubernetes.html), and [Calico](https://docs.projectcalico.org/v3.11/introduction/).
They would be provided as the default CNIs for any pods without explicit annotations.

The work here is based on the following open source projects:
1. [Multus](https://github.com/intel/multus-cni)
1. [SRIOV Device Plugin](https://github.com/intel/sriov-network-device-plugin)
1. [SRIOV CNI](https://github.com/intel/sriov-cni)

For Broadcom Stingray PS225, please refer its [documents](https://github.com/CCX-Stingray/Documentation).


## Initial setup

The SRIOV interfaces should be created before using the SRIOV CNI, for example, if the PF name of one of the Stingray PS225 ethernet NICs in your system is enp8s0f0np0, then you can lookup the maximum supported number of VFs under the PF and create the VFs with the command:

```
#ip link set enp8s0f0np0 up
#cat /sys/class/net/enp8s0f0np0/device/sriov_totalvfs
16
#echo 16 > /sys/class/net/enp8s0f0np0/device/sriov_numvfs
```
For SRIOV CNI with DPDK type drivers, such as vfio-pci, uio_pci_generic, please bind the driver by dpdk-devbind besides creating the VFs, for example:
```dpdk-devbind.py -b vfio-pci enp12s2```
The `enp12s2` is the name of one of VFs of a ethernet NIC.

For more information, please refer the above links in the [Introduction](#Introduction).

##Installation

To install the Multus-SRIOV-Calico or Multus-SRIOV-Flannel, the CNI_TYPE field should be set to 'multus-sriov-calico'
or 'multus-sriov-flannel' correspondingly in the IEC's installation configuration file named as 'config', then do the
CNI installation by setup-cni.sh.

For SRIOV CNI with Flannel by Multus CNI, there are 4 yaml files give:
1. configMap.yaml:
The resource list configuration file for SRIOV device plugin
1. multus-sriov-flannel-daemonsets.yaml
The Multus, SRIOV device plugin&CNI configuration file
1. flannel-daemonset.yml
The Flannel CNI installation file
1. sriov-crd.yaml
The SRIOV CNI configuration file for the attached SRIOV interface resource.

For SRIOV CNI with Calico by Multus CNI, there are 4 yaml files give:
1. configMap.yaml:
The resource list configuration file for SRIOV device plugin
1. multus-sriov-calico-daemonsets.yaml
The Multus, SRIOV device plugin&CNI configuration file
1. calico-daemonset.yaml
The Flannel CNI installation file
1. sriov-crd.yaml
The SRIOV CNI configuration file for the attached SRIOV interface resource.

Usually users should modify the `configMap.yaml` and `sriov-crd.yaml` with their own corresponding networking configuration before doing the installation.

A quick installation script is given as `install.sh`, and the uninstallation could be done by call the `uninstall.sh`.Before you call the install.sh manually to do the install, you should set your desired POD_NETWORK or other parameters in the installation yaml files as we do in the setup-cni.sh.

For Kubernets version >=1.16, there are some changes for Kubernetes API. There is a sample installation script for multus-sriov-calico named as install-k8s-v1.16.sh, which could be used as a sample when your K8s version >=1.16.

**The `install.sh` should be called after the Kubernetes cluster had been installed but before installing the CNIs.**

2 sample user pods yaml files using the SRIOV CNI are given also, please see `pod1.yaml` and `pod2.yaml` in the directory, and 2 iperfv2 based yaml files are also provided to facilitate the performance test. We choose IPerfv2 instead of the IPerfv3 because it seems can support multi-threaded sending/receiving. The 4 yaml files here are provided just for arm64 platform and they could easily be adapted to amd64 platform with corresponding images with a docker building based on the provided Dockerfile.iperf2 file.


## Notes
Current installation files are suitable for K8s version less than 1.6, for that equal to or greater than 1.6, some modifications to the installation files should be done, which would adapt to the K8s api changes for newer versions.
We would try to give a sample installation file for k8s 1.6 or above in the future, but it had not tested now.

The command `kubectl get node $(hostname) -o json | jq '.status.allocatable'` can be used to check whether the allocated resources are available to use or not.

## Other References
[Advanced Networking Features in
Kubernetes and Container Bare Metal](https://builders.intel.com/docs/networkbuilders/adv-network-features-in-kubernetes-app-note.pdf)

[Kubernetes: Multus + SRIOV quickstart](https://zshisite.wordpress.com/2018/11/15/kubernetes-multus-sriov-quickstart/)

