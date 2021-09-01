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
        DC2privateIP
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
param localGatewayIpAddress string = '${clientIP}'


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

resource gatewayName_resource 'Microsoft.Network/virtualNetworkGateways@2015-05-01-preview' = {
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
        name: 'OrtusMonor-allow-rdp'
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
///  Public IP for DC Load Balancer
///
/////////////////////////////////////////////////

param publicIPAddressName string = 'LB-PublicIP'

resource pip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIPAddressName
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
///  Public IP for APP Load Balancer
///
/////////////////////////////////////////////////

param APPpublicIPAddressName string = 'APP-LB-PublicIP'

resource apppip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: APPpublicIPAddressName
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
///  Public IP for WVD Load Balancer - NOT USED
///
/////////////////////////////////////////////////
/*
param WVDpublicIPAddressName string = 'WVD-PIP'

resource wvdpip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: WVDpublicIPAddressName
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
*/


//////////////////////////////////////////////////
///
/// DC's Load Balancer
///
/////////////////////////////////////////////////

param LBname string = 'LB'
param DC1CustomRDPport int
param DC2CustomRDPport int
  
resource Loadbalancer 'Microsoft.Network/loadBalancers@2018-10-01' = {
  name: LBname
  location: location
  sku:{
    name: 'Basic'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LBBAP'
      }
    ]
    inboundNatRules: [
      {
        name: 'DC1-RDP-TCP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LBname, 'LBFE')
          }
          protocol: 'Tcp'
          frontendPort: DC1CustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'DC1-RDP-UDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LBname, 'LBFE')
          }
          protocol: 'Udp'
          frontendPort: DC1CustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'DC2-RDP-TCP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LBname, 'LBFE')
          }
          protocol: 'Tcp'
          frontendPort: DC2CustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'DC2-RDP-UDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', LBname, 'LBFE')
          }
          protocol: 'Udp'
          frontendPort: DC2CustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
  }
}

//////////////////////////////////////////////////
///
/// APP Load Balancer
///
/////////////////////////////////////////////////

param APPLBname string = 'APP-LB'
param APPCustomRDPport int
  
resource APPLoadbalancer 'Microsoft.Network/loadBalancers@2018-10-01' = {
  name: APPLBname
  location: location
  sku:{
    name: 'Basic'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'APPLBFE'
        properties: {
          publicIPAddress: {
            id: apppip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'APPLBBAP'
      }
    ]
    inboundNatRules: [
      {
        name: 'APP-RDP-TCP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', APPLBname, 'APPLBFE')
          }
          protocol: 'Tcp'
          frontendPort: APPCustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
      {
        name: 'APP-RDP-UDP'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', APPLBname, 'APPLBFE')
          }
          protocol: 'Udp'
          frontendPort: APPCustomRDPport
          backendPort: 3389
          enableFloatingIP: false
        }
      }
    ]
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

param DC1name string = 'DC1-test'
param DC2name string = 'DC2-test'
param APPname string = 'APP-test'

param vmSize string = 'Standard_B1ms' 
param vnetPrefix string

param DC1networkInterfaceName string = 'DC1interface'
param DC2networkInterfaceName string = 'DC2interface'
param APPnetworkInterfaceName string = 'APPinterface'

param DC1diagStorageAccountName string = concat('dc1diags', uniqueString(resourceGroup().id))
param DC2diagStorageAccountName string = concat('dc2diags', uniqueString(resourceGroup().id))
param APPdiagStorageAccountName string = concat('appdiags', uniqueString(resourceGroup().id))


param DC1privateIP string = '${vnetPrefix}.10'
param DC2privateIP string = '${vnetPrefix}.11'
param APPprivateIP string = '${vnetPrefix}.12'


var subnetRef = '${vnet.id}/subnets/${subnetName}'
var wgSubnetRef = '${vnet.id}/subnets/${wgSubnetName}'

var availabilitySetNameVar = 'AS'

//////////////////////////////////////////////////
///
///  Create Availability Set
///
/////////////////////////////////////////////////

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2020-12-01' = {
    name: availabilitySetNameVar
    location: location
    sku:{
      name: 'Aligned'
    }
    properties: {
      platformFaultDomainCount: 2
      platformUpdateDomainCount: 5
    }
  }


//////////////////////////////////////////////////
///
///  VM Nic creation
///
/////////////////////////////////////////////////

  resource DC1nic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: DC1networkInterfaceName
    location: location
    dependsOn:[
      Loadbalancer
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: DC1privateIP
            loadBalancerBackendAddressPools:[
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LBname, 'LBBAP')
              }
            ]
            loadBalancerInboundNatRules: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', LBname, 'DC1-RDP-TCP') 
              }
            ]
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
      Loadbalancer
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: DC2privateIP
            loadBalancerBackendAddressPools:[
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', LBname, 'LBBAP')
              }
            ]
            loadBalancerInboundNatRules: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', LBname, 'DC2-RDP-TCP')
              }
            ]

          }
        }
      ]
      networkSecurityGroup: {
        id: nsg.id
      }
    }
  }

  resource APPnic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
    name: APPnetworkInterfaceName
    location: location
    dependsOn:[
      APPLoadbalancer
    ]
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            subnet: {
              id: subnetRef
            }
            privateIPAllocationMethod: 'Static'
            privateIPAddress: APPprivateIP
            loadBalancerBackendAddressPools:[
              {
                id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', APPLBname, 'APPLBBAP')
              }
            ]
            loadBalancerInboundNatRules: [
              {
                id: resourceId('Microsoft.Network/loadBalancers/inboundNatRules', APPLBname, 'APP-RDP-TCP')
              }
            ]
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
      availabilitySet: {
        id: resourceId('Microsoft.Compute/availabilitySets', availabilitySetNameVar) 
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter-smalldisk'
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
          diskSizeGB: 32
          lun: 0
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
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
      availabilitySet: {
        id: resourceId('Microsoft.Compute/availabilitySets', availabilitySetNameVar) 
      }
      hardwareProfile: {
        vmSize: vmSize
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2019-Datacenter-smalldisk'
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
            diskSizeGB: 32
            lun: 0
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: 'Standard_LRS'
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


  resource APPvm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: APPname
    location: location
    dependsOn:[
      APPnic
    ]
    properties: {
      osProfile: {
        computerName: APPname
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
          sku: '2019-Datacenter-smalldisk'
          version: 'latest'
        }
        osDisk: {
          name: 'APP-osdisk'
          createOption: 'FromImage'
          diskSizeGB: 64
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        dataDisks: [
          {
            name: 'APP-datadisk1'
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
            id: APPnic.id
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: APPdiagsAccount.properties.primaryEndpoints.blob
        }
      }
    }
  }
  
  resource APPdiagsAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
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
param WireguardConfNum string
param WireguardStartingIP string
param WGadminPassword string
param dnsLabelPrefix string = toLower('wireguard-123123123d-${uniqueString(resourceGroup().id)}')
param ubuntuOSVersion string = '20_04-lts'
param WGvmSize string = 'Standard_F2s' 
param networkSecurityGroupName string = 'WG-NSG'
var acceleratedNetworking = 'True'
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
   enableAcceleratedNetworking: true
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


//output administratorUsername string = adminUsername
//output hostname string = publicIP.properties.dnsSettings.fqdn
//output sshCommand string = 'ssh${adminUsername}@${publicIP.properties.dnsSettings.fqdn}'


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

resource DC1vmName_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${DC1name}/WinRMCustomScriptExtension'
  location: resourceGroup().location
  dependsOn: [
    DC1vm
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://ortusmediastorage.blob.core.windows.net/public/ConfigDC1.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigDC1.ps1 ${domainName} ${netBiosName} ${adminPassword} ${OUpath} ${clientName} ${officelocation} ${UPNsuffix}'
    }
  }
  
}

resource DC2vmName_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${DC2name}/WinRMCustomScriptExtension'
  location: resourceGroup().location
  dependsOn: [
    DC2vm
    DC1vmName_WinRMCustomScriptExtension
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://ortusmediastorage.blob.core.windows.net/public/ConfigDC2.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigDC2.ps1 ${domainName} ${adminPassword}'
    }
  }
  
}

resource APPvmName_WinRMCustomScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2020-12-01' = {
  name: '${APPname}/WinRMCustomScriptExtension'
  location: resourceGroup().location
  dependsOn: [
    APPvm
    DC1vmName_WinRMCustomScriptExtension
  ]
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://ortusmediastorage.blob.core.windows.net/public/ConfigAPP.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -file ConfigAPP.ps1 ${domainName} ${OUpath} ${clientName} ${adminPassword}'
    }
  }
}

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

@description('Resource group of Compute VM containing the workload')
param vmResourceGroup string = resourceGroup().name

@description('Backup Policy Name')
param policyName string = 'AzureBackup'

var backupFabric = 'Azure'

var protectionContainerDC1 = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${DC1name}'
var protectedItemDC1 = 'vm;iaasvmcontainerv2;${resourceGroup().name};${DC1name}'
var protectionContainerAPP = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${APPname}'
var protectedItemAPP = 'vm;iaasvmcontainerv2;${resourceGroup().name};${APPname}'

var testPolicy = 'DefaultPoliy'

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
    DC2vmName_WinRMCustomScriptExtension
  ]
}

resource vaultName_backupFabric_protectionContainer_protectedItemAPP 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName_var}/${backupFabric}/${protectionContainerAPP}/${protectedItemAPP}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: vaultName_policyName.id
    sourceResourceId: APPvm.id
  }
  dependsOn: [
    vaultName
    DC2vmName_WinRMCustomScriptExtension
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
          count: 180
          durationType: 'Days'
        }
      }
      weeklySchedule: {
        daysOfTheWeek: [
            'Sunday'
        ]
        retentionTimes: [
            '2021-04-07T03:00:00.000Z'
        ]
        retentionDuration: {
          count: 12
          durationType: 'Weeks'
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
          count: 60
          durationType: 'Months'
        }
      }
      yearlySchedule: {
        retentionScheduleFormatType: 'Weekly'
        monthsOfYear: [
            'January'
        ]
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
          count: 7
          durationType: 'Years'
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
