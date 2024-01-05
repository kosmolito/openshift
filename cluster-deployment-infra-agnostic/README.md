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

