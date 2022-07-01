# Multus/SRIOV CNI&Device Plugin Support for IEC


## Introduction
The install/uninstall scripts(install.sh/uninstall.sh) in this folder provide Multus with SRIOV CNI/Calico CNI installation samples with the latest release of Multus/SRIOV CNI/SRIOV Device Plugin.

The work here is based on the following open source projects:
1. [Multus](https://github.com/k8snetworkplumbingwg/multus-cni)
1. [SRIOV Device Plugin](https://github.com/k8snetworkplumbingwg/sriov-network-device-plugin)
1. [SRIOV CNI](https://github.com/k8snetworkplumbingwg/sriov-cni)

Upgrade to the latest version of above components, the image/commit id of each component:
1. Multus:
image: ghcr.io/k8snetworkplumbingwg/multus-cni:stable
1. SRIOV Device Plugin:
image built based on:
commit id: 6fff085aed911388f6cd5d9576901e073681d62e
1. SRIOV CNI:
image built based on:
commit id: ba420ed48a87033a91c9f825d3581f60046a2ae8
