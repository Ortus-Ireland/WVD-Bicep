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
///  Create Resource Groups
///
/////////////////////////////////////////////////

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
        
  }
}


