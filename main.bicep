targetScope = 'subscription'

//////////////////////////////////////////////////
///
///  Edit the below parameters
///
/////////////////////////////////////////////////

@secure()
@description('VM local Admin Password')
param adminPassword string

@secure()
@description('Wireguard Admin Password')
param WGadminPassword string
param WireguardConfNum string
param WireguardStartingIP string

@description('Custom Port for DC1 between 50000 and 63000')
param DC1CustomRDPport int
@description('Custom Port for DC2 between 50000 and 63000')
param DC2CustomRDPport int
@description('Custom Port for APP between 50000 and 63000')
param APPCustomRDPport int
@description('Custom Port for WVD between 50000 and 63000')
param WVDCustomRDPport int

param clientName string = 'robortustest'
param vnetPrefix string = '172.16.173'
param clientIP string = '78.143.138.203'

@description('Local Network CIDR block eg: 192.168.10.0/24')
param localGatewayAddressPrefix string = '192.168.80.0/24'

@description('Gateway VPN Shared Key')
param sharedKey string

param domainName string = 'ad.${clientName}.ie'
param netBiosName string = 'rt'
param OUpath string = 'DC=ad,DC=${clientName},DC=ie'
param officelocation string = 'Dublin'
param UPNsuffix string = 'robortustest.ie'

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

param vnetName string = 'vnet'
param vnetaddressPrefix string ='${vnetPrefix}.0/24'
param subnetPrefix string = '${vnetPrefix}.0/25'
param gatewaySubnetPrefix string = '${vnetPrefix}.128/29'
param wgSubnetPrefix string = '${vnetPrefix}.144/29'
param vnetLocation string = 'northeurope'
param subnetName string = 'subnet'
param gatewaySubnetName string = 'gatewaySubnet'
param wgSubnetName string = 'wireguardSubnet'
param nsgNAME string = 'NSG'
param LBname string = 'LB'
param APPLBName string = 'APP-LB'
param publicIPAddressName string = 'LB-PublicIP'
param APPpublicIPAddressName string = 'APP-LB-PublicIP'
param LBFEname string = 'LB-frontEnd'

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
param preferredAppGroupType string = 'Desktop'
param wvdbackplanelocation string = 'northeurope'
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param logAnalyticsWorkspaceName string = 'LAWorkspace'         

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
    wgSubnetName: wgSubnetName
    localGatewayAddressPrefix: localGatewayAddressPrefix
    sharedKey: sharedKey
    vnetName: vnetName
    subnetName: subnetName
    gatewaySubnetName: gatewaySubnetName
    nsgName: nsgNAME
    clientIP: clientIP  
    publicIPAddressName: publicIPAddressName
    APPpublicIPAddressName: APPpublicIPAddressName
    LBname: LBname
    APPLBname: APPLBName
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
    //WVDCustomRDPport: WVDCustomRDPport
    
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
    preferredAppGroupType: preferredAppGroupType
    wvdbackplanelocation: wvdbackplanelocation
    hostPoolType: hostPoolType
    loadBalancerType: loadBalancerType

  }
}

