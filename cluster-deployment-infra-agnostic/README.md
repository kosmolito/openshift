# Openshift Cluster Deployment

## About

I believe that the best way to learn something is to do it. So, I decided to automate the process of creating an OpenShift cluster on my local server. As the process of creating a cluster is quite complex, I decided to create a guide and some scripts to automate the process. The benefit of this is that I can easily create a cluster. This makes it easier to experiment with OpenShift and I can also easily create a new cluster if I mess up the current one.

## Prerequisites

- An Redhat account [Redhat Openshift Cluster Manager](https://cloud.redhat.com/openshift/install)

- 6 VMs total
  - 1 VM for DNS, NFS, and Load Balancer 2 Core, 4GB RAM, 120GB Storage, CentOS 8 installed
  - 3 VMs for Master Nodes 8 VCPU, 16GB RAM, 250GB Storage
  - 2 VMs for Worker Nodes 8 VCPU, 16GB RAM, 250GB Storage
- server with a static IP address or DHCP reservation
- PowerShell 7 installed on your local machine
  - (Will be used to run the script and generate necessary files)

## Instructions

- 1. Open the `setup.ps1` file in PowerShell 7.
- 2. Change the variables at the top of the file to match your environment.
- 3. Run the PowerShell script.

> **Note:** It will generate a folder with the name of your cluster + the domain name. This folder will contain the necessary files to setup the cluster.

- 4. In the folder that was generated, there will be a `README.md` file. This file will contain the **instructions for your specific cluster**.

- 5. Follow the instructions in the `README.md` file to setup your cluster.

### Happy Clustering
