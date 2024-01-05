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
