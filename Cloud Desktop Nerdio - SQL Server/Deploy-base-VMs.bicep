//////////////////////////////////////////////////
///
///  Storage Account Creation
///
/////////////////////////////////////////////////

param storageAccountName string
param location string
param storageSKU string
param storageKind string

resource sa 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name : storageAccountName
  location : location
  kind : storageKind
  sku: {
    name: storageSKU
  }
}

//////////////////////////////////////////////////
///
///  VNET and Subnet creation
///
/////////////////////////////////////////////////

param vnetName string = 'vnet'
param vnetaddressPrefix string
param subnetPrefix string
param subnetName string = 'subnet'
param gatewaySubnetPrefix string
param gatewaySubnetName string = 'gatewaySubnet'
param wgSubnetPrefix string
param wgSubnetName string = 'wireguardSubnet'
param clientIP string

resource vnet 'Microsoft.Network/virtualnetworks@2015-05-01-preview' = {
  name: vnetName
  location: location
   properties: {
    addressSpace: {
      addressPrefixes: [
        vnetaddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
      {
        name: gatewaySubnetName
        properties:{
            addressPrefix: gatewaySubnetPrefix
        }
      }
      {
        name: wgSubnetName
        properties:{
            addressPrefix: wgSubnetPrefix
            routeTable: {
              id: routeTable.id
            }
        }
      }
    ]
    dhcpOptions:{
      dnsServers:[
        DC1privateIP
        '8.8.8.8'
      ]
    }
  }
}

//////////////////////////////////////////////////
///
///  Local Gateway creation
///
/////////////////////////////////////////////////

param localGatewayName string = '${clientName}-Network'
param localGatewayAddressPrefix string
param localGatewayIpAddress string = clientIP


resource localGatewayName_resource 'Microsoft.Network/localNetworkGateways@2015-05-01-preview' = {
  name: localGatewayName
  location: resourceGroup().location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        localGatewayAddressPrefix
      ]
    }
    gatewayIpAddress: localGatewayIpAddress
  }
}

//////////////////////////////////////////////////
///
///  Virtual Network Gateway creation
///
/////////////////////////////////////////////////

param gatewayPublicIPName string = 'gatewayPIP'
param gatewayName string = 'Gateway'
var gatewaySubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, gatewaySubnetName)


resource gatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: gatewayPublicIPName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2021-03-01' = {
  name: gatewayName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: gatewaySubnetRef
          }
          publicIPAddress: {
            id: gatewayPublicIPName_resource.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: 'Basic'
      tier: 'Basic'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
  dependsOn: [
    vnet
  ]
}


//////////////////////////////////////////////////
///
///  Gateway Connection creation
///
/////////////////////////////////////////////////

param connectionName string = '${clientName}Connection'
param sharedKey string

resource connectionName_resource 'Microsoft.Network/connections@2015-06-15' = {
  name: connectionName
  location: resourceGroup().location
  properties: {
    virtualNetworkGateway1: {
      id: gatewayName_resource.id
    }
    localNetworkGateway2: {
      id: localGatewayName_resource.id
    }
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: sharedKey
  }
}

//////////////////////////////////////////////////
///
///  NSG creation
///
/////////////////////////////////////////////////

param nsgName string = 'NSG'


resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'OrtusCloud-allow-rdp'
        properties: {
          priority: 101
          sourceAddressPrefix: '13.69.144.194'
          protocol: '*'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'OrtusDublin-allow-rdp'
        properties: {
          priority: 102
          sourceAddressPrefix: '78.143.138.203'
          protocol: '*'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'OrtusPreston-allow-rdp'
        properties: {
          priority: 103
          sourceAddressPrefix: '86.47.40.84'
          protocol: '*'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'OrtusManor-allow-rdp'
        properties: {
          priority: 104
          sourceAddressPrefix: '83.70.173.185'
          protocol: '*'
          destinationPortRange: '3389'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'ClientDNSrule'
        properties: {
          priority: 105
          sourceAddressPrefix: clientIP
          protocol: '*'
          destinationPortRange: '53'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }

      }
    ]
  }
}

//////////////////////////////////////////////////
///
///  Public IP for DC1
///
/////////////////////////////////////////////////

param DC1publicIPAddressName string = 'DC1-PublicIP'

resource DC1pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: DC1publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

//////////////////////////////////////////////////
///
///  Public IP for DC2 
///
/////////////////////////////////////////////////

param DC2publicIPAddressName string = 'DC2-PublicIP'

resource DC2pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: DC2publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

//////////////////////////////////////////////////
///
///  Public IP for FILE
///
/////////////////////////////////////////////////

param FILEpublicIPAddressName string = 'File-PublicIP'

resource FILEpip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: FILEpublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}


//////////////////////////////////////////////////
///
///  VM Variables
///
/////////////////////////////////////////////////

param localAdminUser string = 'localadmin'

@secure()
param adminPassword string

param DC1name string = 'DC1'
param DC2name string = 'DC2'
param FILEname string = 'FILE'

param vmSize string = 'Standard_B1ms' 
param vnetPrefix string

param DC1networkInterfaceName string = 'DC1interface'
param DC2networkInterfaceName string = 'DC2interface'
param FILEnetworkInterfaceName string = 'FILEinterface'


param DC1diagStorageAccountName string = concat('dc1diags', uniqueString(resourceGroup().id))
param DC2diagStorageAccountName string = concat('dc2diags', uniqueString(resourceGroup().id))
param APPdiagStorageAccountName string = concat('filediags', uniqueString(resourceGroup().id))


param DC1privateIP string = '${vnetPrefix}.10'
param DC2privateIP string = '${vnetPrefix}.11'
param FILEprivateIP string = '${vnetPrefix}.12'



var subnetRef = '${vnet.id}/subnets/${subnetName}'
var wgSubnetRef = '${vnet.id}/subnets/${wgSubnetName}'

//////////////////////////////////////////////////
///
///  VM Nic creation
///
/////////////////////////////////////////////////

  resource DC1nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: DC1networkInterfaceName
    location: location
    dependsOn:[
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            publicIPAddress: {
              id: DC1pip.id
            }
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: DC1privateIP
          }
        }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }

  resource DC2nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: DC2networkInterfaceName
    location: location
    dependsOn:[
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            publicIPAddress: {
              id: DC2pip.id
            }
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: DC2privateIP
          }
        }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }

  resource FILEnic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: FILEnetworkInterfaceName
    location: location
    dependsOn:[
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            publicIPAddress: {
              id: FILEpip.id
            }
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: FILEprivateIP     
          }
        }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }

  //////////////////////////////////////////////////
  ///
  ///  DC1 Server Deploy
  ///
  /////////////////////////////////////////////////


  resource DC1vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: DC1name
    location: location
    tags:{
      Domain_Controller : 'Primary'
      Role: 'WireGuardKeyHost'
    } 
    dependsOn:[
      DC1nic
    ]
    properties: {
      
      osProfile: {
        computerName: DC1name
        adminUsername: localAdminUser
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
        }
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-Datacenter-smalldisk'
          version: 'latest'
        }
        osDisk: {
          name: 'DC1-osdisk'
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        dataDisks: [
          {
          name: 'DC1-datadisk'  
          diskSizeGB: 4
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          }
        ]
      }
      networkProfile: {
        networkInterfaces: [
          {
            properties: {
              primary: true
            }
            id: DC1nic.id
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: DC1diagsAccount.properties.primaryEndpoints.blob
        }
      }
    }
  }
  
  resource DC1diagsAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: DC1diagStorageAccountName
    location: location
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'Storage'
  }

//////////////////////////////////////////////////
///
///  DC2 Server Deploy
///
/////////////////////////////////////////////////

  resource DC2vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: DC2name
    location: location
    tags: {
      Domain_Controller : 'Secondary'
    }
    dependsOn:[
      DC2nic
    ]
    properties: {
      
      osProfile: {
        computerName: DC2name
        adminUsername: localAdminUser
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
        }
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-Datacenter-smalldisk'
          version: 'latest'
        }
        osDisk: {
          name: 'DC2-osdisk'
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        dataDisks: [
          {
            name: 'DC2-datadisk'
            diskSizeGB: 4
            lun: 0
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: 'Premium_LRS'
            }
            }
        ]
      }
      networkProfile: {
        networkInterfaces: [
          {
            properties: {
              primary: true
            }
            id: DC2nic.id
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: DC2diagsAccount.properties.primaryEndpoints.blob
        }
      }
    }
  }
  
  resource DC2diagsAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: DC2diagStorageAccountName
    location: location
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'Storage'
  }
  

  //////////////////////////////////////////////////
  ///
  ///  App Server Deploy
  ///
  /////////////////////////////////////////////////


  resource FILEvm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: FILEname
    location: location
    dependsOn:[
      FILEnic
    ]
    properties: {
      osProfile: {
        computerName: FILEname
        adminUsername: localAdminUser
        adminPassword: adminPassword
        windowsConfiguration: {
          provisionVMAgent: true
        }
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2022-Datacenter-smalldisk'
          version: 'latest'
        }
        osDisk: {
          name: 'FILE-osdisk'
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        dataDisks: [
          {
            name: 'FILE-datadisk1'
            diskSizeGB: 128
            lun: 0
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: 'Premium_LRS'
            }
          }
        ]
      }
      networkProfile: {
        networkInterfaces: [
          {
            properties: {
              primary: true
            }
            id: FILEnic.id
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: FILEdiagsAccount.properties.primaryEndpoints.blob
        }
      }
    }
  }
  
  resource FILEdiagsAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: APPdiagStorageAccountName
    location: location
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'Storage'
  }

//////////////////////////////////////////////////
///
///  Wireguard Deploy - *** TIDY UP CODE ***
///
/////////////////////////////////////////////////


param WGvmName string = 'Wireguard'
param WGadminUsername string = 'ortusadmin'
param authenticationType string = 'password'
param wgPrivateIP string = '${vnetPrefix}.148'
param allowedIPs string = '${vnetPrefix}.0/24'
param WireguardConfNum string = '230'
param WireguardStartingIP string = '10'
param WGadminPassword string
param dnsLabelPrefix string = toLower('wireguard-${uniqueString(resourceGroup().id)}')
param ubuntuOSVersion string = '20_04-lts'
param WGvmSize string = 'Standard_B1ms' 
param networkSecurityGroupName string = 'WG-NSG'
var WGpublicIPAddressName = '${WGvmName}PublicIP'
var networkInterfaceName = '${WGvmName}NetInt'
var osDiskType = 'Standard_LRS'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${WGadminUsername}/.ssh/authorized_keys'
        keyData: WGadminPassword
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: wgSubnetRef
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: wgPrivateIP
            publicIPAddress: {
            id: publicIP.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: WGnsg.id
    }
   enableAcceleratedNetworking: false
   enableIPForwarding: true
  }
}

resource WGnsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '13.69.144.194'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
      {
        name: 'WG'
        properties:{
          priority: 350
          protocol: 'Udp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'

        }
      }
    ]
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: WGpublicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
  sku: {
    name: 'Basic'
  }
}

resource WGvm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: WGvmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: WGvmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'Canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: ubuntuOSVersion
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
    osProfile: {
      computerName: WGvmName
      adminUsername: WGadminUsername
      adminPassword: WGadminPassword
      linuxConfiguration: any(authenticationType == 'password' ? null : linuxConfiguration) // TODO: workaround for https://github.com/Azure/bicep/issues/449
    }
  }
}


//////////////////////////////////////////////////
///
///  Custom Execution Scripts
///
/////////////////////////////////////////////////

param domainName string
param netBiosName string
param clientName string
param OUpath string
param officelocation string
param UPNsuffix string

resource wg 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${WGvmName}/wireguard'
  location: location
  dependsOn: [
    WGvm
  ]
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/Ortus-Ireland/wgConfig/main/wg-init.sh'
      ]
      commandToExecute: 'sudo sh wg-init.sh ${WireguardConfNum} ${WireguardStartingIP} ${publicIP.properties.ipAddress} ${WGadminUsername} ${DC1privateIP} ${DC2privateIP} ${allowedIPs}'
      // commandToExecute: 'sudo apt install git && git config --global user.name "RealDeclan" && git config --global user.email "ddunne@ortus.ie && git clone https://github.com/Ortus-Ireland/WG-Deploy-VM-Bicep.git"'
    }
  }
}

//////////////////////////////////////////////////
///
///  Recovery Services Vault
///
/////////////////////////////////////////////////

@description('Name of the Vault')
param vaultName_var string = '${clientName}-Backup'

@description('Backup Policy Name')
param policyName string = 'AzureBackup'

var backupFabric = 'Azure'

var protectionContainerDC1 = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${DC1name}'
var protectedItemDC1 = 'vm;iaasvmcontainerv2;${resourceGroup().name};${DC1name}'
var protectionContainerFILE = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${FILEname}'
var protectedItemFILE = 'vm;iaasvmcontainerv2;${resourceGroup().name};${FILEname}'

resource vaultName 'Microsoft.RecoveryServices/vaults@2020-02-02' = {
  name: vaultName_var
  location: location
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

resource vaultName_vaultstorageconfig 'Microsoft.RecoveryServices/vaults/backupstorageconfig@2018-12-20' = {
  name: '${vaultName.name}/vaultstorageconfig'
  dependsOn:[
    DC1vm
  ]
  properties: {
    storageModelType: 'LocallyRedundant'
    crossRegionRestoreFlag: false
  }
}

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName_var}/${backupFabric}/${protectionContainerDC1}/${protectedItemDC1}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: vaultName_policyName.id
    sourceResourceId: DC1vm.id
  }
  dependsOn: [
    vaultName
  ]
}

resource vaultName_backupFabric_protectionContainer_protectedItemAPP 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName_var}/${backupFabric}/${protectionContainerFILE}/${protectedItemFILE}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: vaultName_policyName.id
    sourceResourceId: FILEvm.id
  }
  dependsOn: [
    vaultName
  ]
}

//////////////////////////////////////////////////
///
///  Recovery Services Vault - Backup Policy
///
/////////////////////////////////////////////////

var BackupPolicyName = '${vaultName.name}/${policyName}'

resource vaultName_policyName 'Microsoft.RecoveryServices/vaults/backupPolicies@2020-12-01' = {
  name: BackupPolicyName
  properties: {
    backupManagementType: 'AzureIaasVM'
    timeZone: 'GMT Standard Time'
    instantRpRetentionRangeInDays: 2
    schedulePolicy: {
          schedulePolicyType: 'SimpleSchedulePolicy'
          scheduleRunFrequency: 'Daily'
          scheduleRunTimes: [
            '2021-04-07T03:00:00.000Z'
          ]
    }
    retentionPolicy: {
      dailySchedule: {
        retentionTimes: [
            '2021-04-07T03:00:00.000Z'
        ]
        retentionDuration: {
          count: 92
          durationType: 'Days'
        }
      }
      monthlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        retentionScheduleWeekly: {
          daysOfTheWeek: [
            'Sunday'
          ]
          weeksOfTheMonth: [
            'First'
          ]
        }
        retentionTimes: [
          '2021-04-07T03:00:00.000Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Months'
        }
      }
      retentionPolicyType: 'LongTermRetentionPolicy'
    }   
  }
}

//////////////////////////////////////////////////
///
///  Route Table Creation
///
/////////////////////////////////////////////////

param wireguardRoute string = 'Wireguard'
param routeId string = 'default'
var wireguardPrefix = '10.200.200.0/24'

resource routeTable 'Microsoft.Network/routeTables@2020-07-01' = {
  name: wireguardRoute
  location: location
  properties: {
    routes: [
      {
        id: routeId
        properties: {
          addressPrefix: wireguardPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: wgPrivateIP
        }
        name: routeId
      }
    ]
    disableBgpRoutePropagation: false
  }
}



output vnet object = vnet
output nsgID string = nsg.id
output subnetRef string = subnetRef
output vaultName_var string = vaultName_var
output vaultName_policyName string = vaultName_policyName.id

