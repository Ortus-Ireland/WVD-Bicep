targetScope = 'subscription'

//////////////////////////////////////////////////
///
///  Edit the below parameters
///
/////////////////////////////////////////////////
@description('Deployment Type')
@allowed([
  'Cloud Workplace / AVD no SQL'
  'AVD with sql2019-ws2022'
  ])
param deploymentType string

@description('Update to match Client ** use lower case NO SPACES **')
param clientName string 

@description('netbios name for client ie: rt')
param netBiosName string

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

@description('Local Network CIDR block eg: 192.168.10.0/24')
param localGatewayAddressPrefix string 

@description('Gateway VPN Shared Key')
param sharedKey string

//Define SQL VM parameters

@description('Windows Server and SQL Offer')
param imageOffer string = 'sql2019-ws2022'

@description('SQL Server Sku')
param sqlSku string = 'Standard'

param domainName string = 'ad.${clientName}.ie'
param OUpath string = 'DC=ad,DC=${clientName},DC=ie'
param officelocation string = 'Dublin'
param UPNsuffix string = '${clientName}.ie'

//Define Backend VM parameters

param location string = 'northeurope'
param resourceGroupName string = '${clientName}-rg'
param storageAccountName string = '${clientName}std'
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
    domainName: domainName
    netBiosName: netBiosName
    officelocation: officelocation
    OUpath: OUpath
    UPNsuffix: UPNsuffix
  }
}

module DeploySQL 'Deploy-SQL.bicep' = if (deploymentType == 'AVD with sql2019-ws2022'){
  name: 'DeploySQL'
  scope: resourceGroup(rg.name)
  params:{
    location: location
    adminPassword: adminPassword
    vnetPrefix: vnetPrefix
    vnet: DeployVMs.outputs.vnet
    nsgID: DeployVMs.outputs.nsgID
    subnetRef: DeployVMs.outputs.subnetRef
    vaultName_var: DeployVMs.outputs.vaultName_var
    vaultName_policyName: DeployVMs.outputs.vaultName_policyName
    imageOffer: imageOffer
    sqlSku: sqlSku
  }
}

