..
      Licensed under the Apache License, Version 2.0 (the "License"); you may
      not use this file except in compliance with the License. You may obtain
      a copy of the License at

          http://www.apache.org/licenses/LICENSE-2.0

      Unless required by applicable law or agreed to in writing, software
      distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
      WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
      License for the specific language governing permissions and limitations
      under the License.

      Convention for heading levels in Integrated Edge Cloud documentation:

      =======  Heading 0 (reserved for the title in a document)
      -------  Heading 1
      ~~~~~~~  Heading 2
      +++++++  Heading 3
      '''''''  Heading 4

      Avoid deeper levels because they do not render well.


=================================
IEC Reference Foundation Overview
=================================

This document provides a general description about the reference foundation of IEC.
The Integrated Edge Cloud (IEC) will enable new functionalities and business models
on the network edge. The benefits of running applications on the network edge are
- Better latencies for end users
- Less load on network since more data can be processed locally
- Fully utilize the computation power of the edge devices

.. _Kubernetes: https://kubernetes.io/
.. _Calico: https://www.projectcalico.org/
.. _Contiv: https://github.com/contiv/vpp
.. _OVN-kubernetes: https://github.com/openvswitch/ovn-kubernetes

Currently, the chosen operating system(OS) is Ubuntu 16.04 and/or 18.04.
The infrastructure orchestration of IEC is based on Kubernetes_, which is a
production-grade container orchestration with rich running eco-system.
The current container networking mechanism (CNI) choosed for Kubernetes is project
Calico, which is a high performance, scalable, policy enabled and widely used container
networking solution with rather easy installation and arm64 support. In the future,
Contiv/VPP or OVN-Kubernetes would also be candidates for Kubernetes networking.


Kubernetes Install for Ubuntu
-----------------------------

Install Docker as Prerequisite
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. _Docker: https://www.docker.com/
.. _install: https://docs.docker.com/install/linux/docker-ce/ubuntu/

Docker_ is used for Kuberntes docker images management. The installation script for docker
version 18.06 is given below. More docker install information can be found in the install_
guide::
    DOCKER_VERSION=18.06.1
    ARCH=arm64
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo apt-key fingerprint 0EBFCD88
    sudo add-apt-repository \
     "deb [arch=${ARCH}] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) \
     stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce=${DOCKER_VERSION}~ce~3-0~ubuntu


Disable swap on your machine
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Turn off all swap devices and files with::

   sudo swapoff -a

.. _kubeadm: https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/


Install Kubernetes with Kubeadm
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

kubeadm_ helps you bootstrap a minimum viable Kubernetes cluster that conforms
to best practices which a preferred installation method for IEC currently.
Now we choose v1.13.0 as a current stable version of Kubernetes for arm64.
Usually the current host(edge server/gateway)'s management interface is chosen as
the Kubeapi-server advertise address which is indicated here as ``$MGMT_IP``.

The common installation steps for both Kubernetes master and slave node are given
as Linux shell scripts::

   sudo bash
   apt-get update && apt-get install -y apt-transport-https curl
   curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
   cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
   deb https://apt.kubernetes.io/ kubernetes-xenial main
   EOF
   apt-get update
   apt-get install -y kubelet=1.13.0-00 kubeadm=1.13.0-00 kubectl=1.13.0-00
   apt-mark hold kubelet kubeadm kubectl
   sysctl net.bridge.bridge-nf-call-iptables=1

For host setup as Kubernetes `master`::

   sudo kubeadm config images pull
   sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --apiserver-advertise-address=$MGMT_IP \
   --service-cidr=172.16.1.0/24

To start using your cluster, you need to run (as a regular user)::

   mkdir -p $HOME/.kube
   sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
   sudo chown $(id -u):$(id -g) $HOME/.kube/config

or if you are the ``root`` user::

   export KUBECONFIG=/etc/kubernetes/admin.conf

For hosts setup as Kubernetes `slave`::

   kubeadm join --token <token> <master-ip>:6443 --discovery-token-ca-cert-hash sha256:<hash>

in which the token is given in the master's ``kubeadm init``.

or using following command which will skip ca-cert verification::

   kubeadm join --token <token> <master_ip>:6443 --discovery-token-unsafe-skip-ca-verification

After the `slave` joining the Kubernetes cluster, in the master node, you could check the cluster
node with the command::
   kubectl get nodes


Install the Calico CNI Plugin to Kubernetes Cluster
---------------------------------------------------

Now we install a Calico_ network add-on so that Kubernetes pods can communicate with each other.
The network must be deployed before any applications. Kubeadm only supports Container Networking
Interface(CNI) based networks for which Calico has supported.

Install the Etcd Database
~~~~~~~~~~~~~~~~~~~~~~~~~

::

   kubectl apply -f https://raw.githubusercontent.com/Jingzhao123/arm64TemporaryCalico/temporay_arm64/
   v3.3/getting-started/kubernetes/installation/hosted/etcd-arm64.yaml

Install the RBAC Roles required for Calico
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   kubectl apply -f https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/rbac.yaml

Install Calico to system
~~~~~~~~~~~~~~~~~~~~~~~~

Firstly, we should get the configuration file from web site and modify the corresponding image
from amd64 to arm64 version. Then, by using kubectl, the calico pod will be created.
::
   wget https://docs.projectcalico.org/v3.3/getting-started/kubernetes/installation/hosted/calico.yaml

Since the "quay.io/calico" image repo does not support does not multi-arch, we have
to replace the “quay.io/calico” image path to "calico" which supports multi-arch.
::
   sed -i "s/quay.io\/calico/calico/" calico.yaml

Deploy the Calico using following command::

   kubectl apply -f calico.yaml

.. Attention::

   In calico.yaml file, there is an option "IP_AUTODETECTION_METHOD" about choosing
   network interface. The default value is "first-found" which means the first valid
   IP address (except local interface, docker bridge). So if the number of network-interface
   is more than 1 on your server, you should configure it depends on your networking
   environments. If it does not configure it properly, there are some error about
   calico-node pod: "BGP not established with X.X.X.X".


Remove the taints on master node
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

::

   kubectl taint nodes --all node-role.kubernetes.io/master-


Verification for the Work of Kubernetes
---------------------------------------

Now we can verify the work of Kubernetes and Calico with Kubernets pod and service creation and accessing
based on Nginx which is a widely used web server.

Firstly, create a file named nginx-app.yaml to describe a Pod and service by::

  $ cat <<EOF >~/nginx-app.yaml
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

then test the Kubernetes working status with the script::

   set -ex
   kubectl create -f ~/nginx-app.yaml
   kubectl get nodes
   kubectl get services
   kubectl get pods
   kubectl get rc
   r="0"
   while [ $r -ne "2" ]
   do
      r=$(kubectl get pods | grep Running | wc -l)
      sleep 60
   done
   svcip=$(kubectl get services nginx  -o json | grep clusterIP | cut -f4 -d'"')
   sleep 10
   wget http://$svcip
   kubectl delete -f ./examples/nginx-app.yaml
   kubectl delete -f ./nginx-app.yaml
   kubectl get rc
   kubectl get pods
   kubectl get services

.. _Helm: https://github.com/helm/helm

Helm Install on Arm64
---------------------

Helm_ is a tool for managing Kubernetes charts. Charts are packages of pre-configured
Kubernetes resources. The installation of Helm on arm64 is as followes::

   wget https://storage.googleapis.com/kubernetes-helm/helm-v2.12.3-linux-arm64.tar.gz
   xvf helm-v2.12.3-linux-arm64.tar.gz
   sudo cp linux-arm64/helm /usr/bin
   sudo cp linux-arm64/tiller /usr/bin


Further Information
-------------------

We would like to provide a walk through shell script to automate the installation of Kubernetes
and Calico in the future. But this README is still useful for IEC developers and users.

For issues or anything on the reference foundation stack of IEC, you could contact:

Trevor Tao: trevor.tao@arm.com

Jingzhao Ni: jingzhao.ni@arm.com

Jianlin Lv:  jianlin.lv@arm.com

