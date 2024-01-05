$ClusterName = "oc2"
$ClusterDomain = "exampledomain.com"
$NetworkAddress = "192.168.20"
$ServiceNode = [pscustomobject]@{
  Name = "openshift-services"
  IP = "$($NetworkAddress).70"
  cpu = 2
  Memory = 4096
  disk = "120G"
  ImageRegistryPath = "/var/nfsshare/image-registry"
  ImageRegistrySize = "100G"
  AppDataPath = "/var/nfsshare/appdata"
  AppDataSize = "10G"
  Role = "infra"
}
$ClusterNodes = @(
  [pscustomobject]@{
      Name = "openshift-master1"
      IP = "$($NetworkAddress).71"
      cpu = 8
      Memory = 16384
      Disk = "250G"
      Role = "master"
  },
  [pscustomobject]@{
      Name = "openshift-master2"
      IP = "$($NetworkAddress).72"
      Cpu = 8
      Memory = 16384
      Disk = "250G"
      Role = "master"
  },
  [pscustomobject]@{
      Name = "openshift-master3"
      IP = "$($NetworkAddress).73"
      Cpu = 8
      Memory = 16384
      Disk = "250G"
      Role = "master"
  },
  [pscustomobject]@{
    Name = "openshift-worker1"
    IP = "$($NetworkAddress).74"
    Cpu = 8
    Memory = 16384
    Disk = "250G"
    Role = "worker"
},
[pscustomobject]@{
    Name = "openshift-worker2"
    IP = "$($NetworkAddress).75"
    Cpu = 8
    Memory = 16384
    Disk = "250G"
    Role = "worker"
}
)

## Remove the last octet from the IP address to get the network address
# $NetworkAddress = $ServiceNode.IP.Substring(0, $ServiceNode.IP.LastIndexOf("."))

# Octets
$Octets = $NetworkAddress.Split(".")

# Reverse the octets
$NetworkAddressReverse = $Octets[2] + "." + $Octets[1] + "." + $Octets[0]


# Remove the first three octets from the IP address to get the last octet, +1 to remove the period (.) from the IP address
$ServiceLastOctet = $ServiceNode.IP.Substring($ServiceNode.IP.LastIndexOf(".") + 1)

$Display = @"  
################################ OpenShift Cluster Configuration ################################
Cluster Name: $ClusterName
Cluster Domain: $ClusterDomain
`n
"@

$Display | Out-Host
Write-Host -NoNewline "########## Infrastructure Node ##########"
$ServiceNode | Format-List
Write-Host -NoNewline "################### Cluster Nodes ###################"
$ClusterNodes | Format-Table -AutoSize
Write-Host "############################################################################################"
Write-Host "PLEASE REVIEW THE ABOVE CONFIGURATION AND PRESS ENTER TO CONTINUE OR CTRL+C TO EXIT"
pause

################# DNS Configuration #################
$dbDomainConfig = @"
`$TTL    604800
@       IN      SOA     $($ServiceNode.Name).$($ClusterDomain). admin.$($ClusterDomain). (
                  1     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      $($ServiceNode.Name)

; name servers - A records
$($ServiceNode.Name).$($ClusterDomain).                                 IN  A   $($ServiceNode.IP)
; OpenShift Container Platform Cluster - A records

$(($ClusterNodes | ForEach-Object {
  $FQDN = $_.Name + "." + $ClusterName + "." + $ClusterDomain + "."
  "`n$FQDN".padright(40) + "IN  A   $($_.IP)"
}))


; OpenShift internal cluster IPs - A records
api.$($ClusterName).$($ClusterDomain).                                  IN  A   $($ServiceNode.IP)
api-int.$($ClusterName).$($ClusterDomain).                              IN  A   $($ServiceNode.IP)
*.apps.$($ClusterName).$($ClusterDomain).                               IN  A   $($ServiceNode.IP)
console-openshift-console.apps.$($ClusterName).$($ClusterDomain).       IN  A   $($ServiceNode.IP)
oauth-openshift.apps.$($ClusterName).$($ClusterDomain).                 IN  A   $($ServiceNode.IP)
$($Index = 0)
$($ClusterNodes | Where-Object { $_.Role -eq "master" } | ForEach-Object {
  $FQDN = "etcd-$($Index)" + "." + $ClusterName + "." + $ClusterDomain + "."
  "`n$FQDN".padright(40) + "IN  A   $($_.IP)"
})


; OpenShift internal cluster IPs - SRV records
_etcd-server-ssl._tcp.$($ClusterName).$($ClusterDomain).    86400       IN    SRV     0    10    2380    etcd-0.$($($ClusterDomain).split(".")[1])
_etcd-server-ssl._tcp.$($ClusterName).$($ClusterDomain).    86400       IN    SRV     0    10    2380    etcd-1.$($($ClusterDomain).split(".")[1])
_etcd-server-ssl._tcp.$($ClusterName).$($ClusterDomain).    86400       IN    SRV     0    10    2380    etcd-2.$($($ClusterDomain).split(".")[1])
"@

################# Reverse DNS #################
$dbIPConfig = @"
`$TTL    604800
@       IN      SOA     $($ServiceNode.Name).$($ClusterDomain). admin.$($ClusterDomain). (
                  6     ; Serial
             604800     ; Refresh
              86400     ; Retry
            2419200     ; Expire
             604800     ; Negative Cache TTL
)

; name servers - NS records
    IN      NS      $($ServiceNode.Name).$($ClusterDomain).

; name servers - PTR records
$ServiceLastOctet    IN    PTR    $($ServiceNode.Name).$($ClusterDomain).

; OpenShift Container Platform Cluster - PTR records

$(($ClusterNodes | ForEach-Object {
  $LastOctet = $_.IP.Substring($_.IP.LastIndexOf(".") + 1)
  $FQDN = $_.Name + "." + $ClusterName + "." + $ClusterDomain + "."
  "`n$LastOctet    IN    PTR    $FQDN"
}))
$ServiceLastOctet    IN    PTR    api.$($ClusterName).$($ClusterDomain).
$ServiceLastOctet    IN    PTR    api-int.$($ClusterName).$($ClusterDomain).
"@

################# Named Configuration #################
$NamedConfig = @"
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
	listen-on port 53 { 127.0.0.1; $($ServiceNode.IP); };
#	listen-on-v6 port 53 { ::1; };
	directory "/var/named";
	dump-file "/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	recursing-file  "/var/named/data/named.recursing";
	secroots-file   "/var/named/data/named.secroots";
	allow-query     { localhost; $($NetworkAddress).0/24; };

	/* 
	 - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion.
	 - If you are building a RECURSIVE (caching) DNS server, you need to enable 
	   recursion. 
	 - If your recursive DNS server has a public IP address, you MUST enable access 
	   control to limit queries to your legitimate users. Failing to do so will
	   cause your server to become part of large scale DNS amplification 
	   attacks. Implementing BCP38 within your network would greatly
	   reduce such attack surface 
	*/
	recursion yes;
	
	forwarders {
                8.8.8.8;
                8.8.4.4;
        };

	dnssec-enable yes;
	dnssec-validation yes;

	/* Path to ISC DLV key */
	bindkeys-file "/etc/named.root.key";

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
include "/etc/named/named.conf.local";
"@

$NamedConfigLocal = @"
zone "$($ClusterDomain)" {
    type master;
    file "/etc/named/zones/db.$($ClusterDomain)"; # zone file path
};

zone "$($NetworkAddressReverse).in-addr.arpa" {
    type master;
    file "/etc/named/zones/db.$($NetworkAddress)";  # $($NetworkAddress).0/24 subnet
};
"@

################# HAProxy Configuration #################
$haproxyConfig = @"
# Global settings
#---------------------------------------------------------------------
global
    maxconn     20000
    log         /dev/log local0 info
    chroot      /var/lib/haproxy
    pidfile     /var/run/haproxy.pid
    user        haproxy
    group       haproxy
    daemon

    # turn on stats unix socket
    stats socket /var/lib/haproxy/stats

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 3
    timeout http-request    10s
    timeout queue           1m
    timeout connect         10s
    timeout client          300s
    timeout server          300s
    timeout http-keep-alive 10s
    timeout check           10s
    maxconn                 20000

listen stats
    bind :9000
    mode http
    stats enable
    stats uri /

frontend $($ClusterName)_k8s_api_fe
    bind :6443
    default_backend $($ClusterName)_k8s_api_be
    mode tcp
    option tcplog

backend $($ClusterName)_k8s_api_be
    balance source
    mode tcp
    $(($ClusterNodes | Where-Object { $_.Role -eq "master" } | ForEach-Object {
      "`n    server      $($_.Name) $($_.IP):6443 check"
    }))

frontend $($ClusterName)_machine_config_server_fe
    bind :22623
    default_backend $($ClusterName)_machine_config_server_be
    mode tcp
    option tcplog

backend $($ClusterName)_machine_config_server_be
    balance source
    mode tcp
    $(($ClusterNodes | Where-Object { $_.Role -eq "master" } | ForEach-Object {
      "`n    server      $($_.Name) $($_.IP):22623 check"
    }))

frontend $($ClusterName)_http_ingress_traffic_fe
    bind :80
    default_backend $($ClusterName)_http_ingress_traffic_be
    mode tcp
    option tcplog

backend $($ClusterName)_http_ingress_traffic_be
    balance source
    mode tcp
    $(($ClusterNodes | ForEach-Object {
      "`n    server      $($_.Name) $($_.IP):80 check"
    }))

frontend $($ClusterName)_https_ingress_traffic_fe
    bind *:443
    default_backend $($ClusterName)_https_ingress_traffic_be
    mode tcp
    option tcplog

backend $($ClusterName)_https_ingress_traffic_be
    balance source
    mode tcp
    $(($ClusterNodes | ForEach-Object {
      "`n    server      $($_.Name) $($_.IP):443 check"
    }))
"@

################# Image Registry Configuration #################
$registryConfig = @"
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: image-registry-pv
spec:
  capacity:
    storage: 100Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: image-registry-storage
    namespace: openshift-image-registry
  accessModes:
  - ReadWriteMany
  nfs:
    path: $($ServiceNode.ImageRegistryPath)
    server: $($ServiceNode.IP)
  persistentVolumeReclaimPolicy: Retain
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  finalizers:
  - kubernetes.io/pvc-protection
  name: image-registry-storage
  namespace: openshift-image-registry
spec:
  accessModes:
  - ReadWriteMany
  resources:
    requests:
      storage: 100Gi
"@

################# Shell Script to run on the Service Node #################
$ShellScript = @"
#!/bin/bash
echo "###### Updating system ######"
dnf update -y

echo "###### Installing packages bind firewalld & haproxy ######"
dnf install -y bind bind-utils nfs-utils firewalld haproxy --allowerasing

echo "###### Enabling and starting firewalld & named ######"
systemctl enable named firewalld
systemctl start named firewalld

echo "###### Configuring bind (local DNS server) ######"
cp named.conf /etc/named.conf
cp named.conf.local /etc/named/
mkdir -p /etc/named/zones
cp db* /etc/named/zones
systemctl restart named

# Configure firewall
echo "###### Configuring firewall ######"
firewall-cmd --permanent --add-port=53/udp
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=22623/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload

# Configure haproxy
echo "###### Configuring haproxy ######"
cp haproxy.cfg /etc/haproxy/haproxy.cfg
setsebool -P haproxy_connect_any 1
systemctl enable haproxy
systemctl start haproxy

# Configure registry
echo "###### Configuring Image registry & Appdata NFS Share ######"
# Enter a value in /etc/exports for the NFS share (Change * to the IP address or subnet of the host that will be mounting the NFS share)
mkdir -p $($ServiceNode.ImageRegistryPath)
mkdir -p $($ServiceNode.AppDataPath)
chown -R nfsnobody:nfsnobody $($ServiceNode.ImageRegistryPath)
chown -R nfsnobody:nfsnobody $($ServiceNode.AppDataPath)
chmod -R 777 $($ServiceNode.ImageRegistryPath)
chmod -R 777 $($ServiceNode.AppDataPath)
systemctl enable nfs-server
systemctl start nfs-server
cat <<EOF > /etc/exports
$($ServiceNode.ImageRegistryPath)  *(rw,sync,no_root_squash)
$($ServiceNode.AppDataPath)  *(rw,sync,no_root_squash)
EOF
# Explnation of the below commands
# exportfs -rav : Export all directories and verify the exports file
exportfs -rav
systemctl restart nfs-server


echo "###### All done ######"
"@

################# NFS Storage Class Configuration #################
$AppDataNFSNameSpace = "nfs"
$NFSProvisionerName = "nfs-storage"
$NFSProvisionerConfig = @"
############## NFS Namespace ##############
apiVersion: v1
kind: Namespace
metadata:
  name: $($AppDataNFSNameSpace)
---
############### Create the service account that the provisioner will use ##############
apiVersion: v1
kind: ServiceAccount
metadata:
  name: nfs-client-provisioner
  namespace: $($AppDataNFSNameSpace)
---
############## Create a cluster role and bind it to the service account ##############
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: nfs-client-provisioner-runner
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
---
############## Bind the service account to the cluster role ##############
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: run-nfs-client-provisioner
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: $($AppDataNFSNameSpace)
roleRef:
  kind: ClusterRole
  name: nfs-client-provisioner-runner
  apiGroup: rbac.authorization.k8s.io
---
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: $($AppDataNFSNameSpace)
rules:
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
---
kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: leader-locking-nfs-client-provisioner
  namespace: $($AppDataNFSNameSpace)
subjects:
  - kind: ServiceAccount
    name: nfs-client-provisioner
    namespace: $($AppDataNFSNameSpace)
roleRef:
  kind: Role
  name: leader-locking-nfs-client-provisioner
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: use-scc-hostmount-anyuid
  namespace: $($AppDataNFSNameSpace)
rules:
- apiGroups:
  - security.openshift.io
  resourceNames:
  - hostmount-anyuid
  resources:
  - securitycontextconstraints
  verbs:
  - use
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: use-scc-hostmount-anyuid
  namespace: $($AppDataNFSNameSpace)
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: use-scc-hostmount-anyuid
subjects:
- kind: ServiceAccount
  name: nfs-client-provisioner
  namespace: $($AppDataNFSNameSpace)
---
############## NFS provisioner deployment ##############
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nfs-client-provisioner
  labels:
    app: nfs-client-provisioner
  namespace: $($AppDataNFSNameSpace)
spec:
  replicas: 1
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: nfs-client-provisioner
  template:
    metadata:
      labels:
        app: nfs-client-provisioner
    spec:
      serviceAccountName: nfs-client-provisioner
      containers:
        - name: nfs-client-provisioner
          image: registry.k8s.io/sig-storage/nfs-subdir-external-provisioner:v4.0.2
          volumeMounts:
            - name: nfs-client-root
              mountPath: /persistentvolumes
          env:
            - name: PROVISIONER_NAME
              value: $($NFSProvisionerName)
            - name: NFS_SERVER
              value: $($ServiceNode.IP)
            - name: NFS_PATH
              value: $($ServiceNode.AppDataPath)
          resources:
            requests:
              memory: "512Mi"
              cpu: "500m"
            limits:
              memory: "1Gi"
              cpu: "1"
      volumes:
        - name: nfs-client-root
          nfs:
            server: $($ServiceNode.IP)
            path: $($ServiceNode.AppDataPath)
---
# NFS storage class
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: nfs-client
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: $($NFSProvisionerName)
parameters:
  # If archiveOnDelete is set to true, when a PVC is deleted, the PV will not be deleted.
  archiveOnDelete: "false"
"@


$ConfigFolder = "$($PSScriptRoot)/$($ClusterName).$($ClusterDomain)-cluster-spec"
$NFSProvisionerFolder = "$($ConfigFolder)/nfs-storage-class-provisioner"


if (!(Test-Path -Path $($ConfigFolder))) {
    New-Item -Path $($ConfigFolder) -ItemType Directory | Out-Null
}

if (!(Test-Path -Path $($NFSProvisionerFolder))) {
    New-Item -Path $($NFSProvisionerFolder) -ItemType Directory | Out-Null
}


