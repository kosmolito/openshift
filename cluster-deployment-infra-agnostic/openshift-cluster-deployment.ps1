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

