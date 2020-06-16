How to use the deploy scripts:

1. the testbed architecture is shown in https://wiki.akraino.org/display/AK/R3+Test+Document+of+IEC+Type+5%3A+SmartNIC+for+Integrated+Edge+Cloud+%28IEC%29+Blueprint+Family
2. you have to setup your own file-server, using nginx or other webserver. The file server contains four files:
   * BlueField-2.5.1.11213.tar.xz
   * core-image-full-dev-BlueField-2.5.1.11213.2.5.3.tar.xz
   * mft-4.14.0-105-x86_64-deb.tgz
   * MLNX_OFED_LINUX-5.0-2.1.8.0-debian8.11-x86_64.tgz (or use the version of your OS)
3. set the ip address of your file_server in bluefield-fs.yaml
4. Then it's ok to run bluefield-fs.yaml. This scripts will install a Linux system in the bluefield card.
5. you have to open dpdk's mlx5 driver in setup when you use ovs-dpdk-fs.yaml scripts.
6. Then you can use the ovs-dpdk-fs.yaml to download ovs-dpdk and compile it on the bluefield card.
