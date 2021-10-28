targetScope = 'subscription'

//////////////////////////////////////////////////
///
///  Edit the below parameters
///
/////////////////////////////////////////////////


@description('Update to match Client ** use lower case NO SPACES **')
param clientName string 
@description('Prefix for client vnet eg: 172.16.173 ** check subnet file for next available **')
param vnetPrefix string
@description('External client IP')
param clientIP string

@secure()
@description('VM local Admin Password')
param adminPassword string

@secure()
@description('Wireguard Admin Password')
param WGadminPassword string
@description('Number of conf files required')
param WireguardConfNum string
@description('Starting IP for clients eg: 10')
param WireguardStartingIP string

@description('Custom Port for DC1 between 50000 and 63000')
param DC1CustomRDPport int
@description('Custom Port for DC2 between 50000 and 63000')
param DC2CustomRDPport int
@description('Custom Port for APP between 50000 and 63000')
param APPCustomRDPport int
@description('Custom Port for AVD Host between 50000 and 63000')
param AVDCustomRDPport int

@description('Expiration time for the HostPool registration token. This must be up to 30 days from todays date.')
param tokenExpirationTime string

@description('Local Network CIDR block eg: 192.168.10.0/24')
param localGatewayAddressPrefix string 

@description('Gateway VPN Shared Key')
param sharedKey string

param netBiosName string
param domainName string = 'ad.${clientName}.ie'
param OUpath string = 'DC=ad,DC=${clientName},DC=ie'
param officelocation string = 'Dublin'
param UPNsuffix string = '${clientName}.ie'

//Define Backend VM parameters

param location string = 'northeurope'
param resourceGroupName string = '${clientName}-rg'
param WVDresourceGroupName string = '${clientName}-wvd-rg'
param storageAccountName string = '${clientName}std'
param DNSPort string = '53'
param RDPPort string = '3389'
param storageSKU string = 'Standard_LRS'
param storageKind string = 'Storage'

//////////////////////////////////////////////////
///
///  Define Networking deployment parameters
///
/////////////////////////////////////////////////

param vnetaddressPrefix string ='${vnetPrefix}.0/24'
param subnetPrefix string = '${vnetPrefix}.0/25'
param gatewaySubnetPrefix string = '${vnetPrefix}.128/29'
param wgSubnetPrefix string = '${vnetPrefix}.144/29'

//////////////////////////////////////////////////
///
///  WVD Parameters
///
/////////////////////////////////////////////////

param hostpoolName string = '${clientName}Hostpool'
param hostpoolFriendlyName string = '${clientName} Cloud Desktop Hostpool'
param appgroupName string = '${clientName}WVDAppGroup'
param appgroupNameFriendlyName string = '${clientName} Cloud Desktop Appgroup'
param workspaceName string = '${clientName}WVDWorkspace'
param workspaceNameFriendlyName string = '${clientName} Cloud Desktop Workspace'

//////////////////////////////////////////////////
///
///  Define Azure Files deployment parameters
///
/////////////////////////////////////////////////

param storageaccountlocation string = 'northeurope'
param storageaccountName string = '${clientName}sa'
param storageaccountkind string = 'FileStorage'
param storgeaccountglobalRedundancy string = 'Premium_LRS'
param fileshareFolderName string = 'fslogix-profilecontainers'

//////////////////////////////////////////////////
///
///  Create Resource Groups
///
/////////////////////////////////////////////////

resource rgwvd 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name : WVDresourceGroupName
  location : location
}
resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name : resourceGroupName
  location : location
}

//////////////////////////////////////////////////
///
///  Call External Modules
///
/////////////////////////////////////////////////

module DeployVMs 'Deploy-base-VMs.bicep' = {
  name: 'DeployVMs'
  scope: resourceGroup(rg.name)
  params:{
    clientName: clientName
    storageAccountName: storageAccountName
    location: location
    storageKind: storageKind
    storageSKU: storageSKU
    vnetaddressPrefix: vnetaddressPrefix
    subnetPrefix: subnetPrefix
    gatewaySubnetPrefix: gatewaySubnetPrefix
    wgSubnetPrefix: wgSubnetPrefix
    localGatewayAddressPrefix: localGatewayAddressPrefix
    sharedKey: sharedKey
    clientIP: clientIP  
    adminPassword: adminPassword
    vnetPrefix: vnetPrefix
    WGadminPassword: WGadminPassword
    WireguardConfNum: WireguardConfNum
    WireguardStartingIP: WireguardStartingIP
    domainName: domainName
    netBiosName: netBiosName
    officelocation: officelocation
    OUpath: OUpath
    UPNsuffix: UPNsuffix
    DC1CustomRDPport: DC1CustomRDPport
    DC2CustomRDPport: DC2CustomRDPport
    APPCustomRDPport: APPCustomRDPport
    WVDCustomRDPport: AVDCustomRDPport
    
  }
}


module DeployWVD 'Deploy-WVD-VMs.bicep' = {
  name: 'DeployWVD'
  scope: resourceGroup(rgwvd.name)
  params:{
    hostpoolName:hostpoolName
    hostpoolFriendlyName: hostpoolFriendlyName
    appgroupName: appgroupName 
    appgroupNameFriendlyName: appgroupNameFriendlyName
    workspaceName: workspaceName
    workspaceNameFriendlyName: workspaceNameFriendlyName
    tokenExpirationTime: tokenExpirationTime
  }
  dependsOn: [
    DeployVMs
  ]
}

