param location string

//////////////////////////////////////////////////
///
///  Public IP for FILE
///
/////////////////////////////////////////////////

param SQLpublicIPAddressName string = 'SQL-PublicIP'

resource SQLpip 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: SQLpublicIPAddressName
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
  

///////////////////////////////////////
///
///  SQL NIC Creation
///
//////////////////////////////////////

param vnet object
param nsgID string
param subnetName string = 'subnet'
param SQLnetworkInterfaceName string = 'SQLinterface'
param subnetRef string
param SQLprivateIP string = '${vnetPrefix}.13'



resource SQLnic 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: SQLnetworkInterfaceName
  location: location
  dependsOn:[
  ]
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          publicIPAddress: {
            id: SQLpip.id
          }
          subnet: {
            id: subnetRef
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: SQLprivateIP     
        }
      }
    ]
    networkSecurityGroup: {
      id: nsgID
    }
  }
}




  
  //////////////////////////////////////////////////
  ///
  ///  SQL Server Deploy
  ///
  /////////////////////////////////////////////////

  param localAdminUser string = 'localadmin'

  @secure()
  param adminPassword string

  param SQLname string = 'SQL'
  param vmSize string = 'Standard_B1ms' 
  param vnetPrefix string

  param SQLdiagStorageAccountName string = concat('sqldiags', uniqueString(resourceGroup().id))

  
  param imageOffer string
  param sqlSku string
  

  resource SQLvm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
    name: SQLname
    location: location
    dependsOn:[
      SQLnic
    ]
    properties: {
      osProfile: {
        computerName: SQLname
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
          publisher: 'MicrosoftSQLServer'
          offer: imageOffer
          sku: sqlSku
          version: 'latest'
        }
        osDisk: {
          name: 'SQL-osdisk'
          createOption: 'FromImage'
          diskSizeGB: 128
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
        dataDisks: [for j in range(0, (sqlDataDisksCount + sqlLogDisksCount)): {
          lun: j
          createOption: dataDisks.createOption
          caching: ((j >= sqlDataDisksCount) ? 'None' : dataDisks.caching)
          writeAcceleratorEnabled: dataDisks.writeAcceleratorEnabled
          diskSizeGB: dataDisks.diskSizeGB
          managedDisk: {
            storageAccountType: dataDisks.storageAccountType
          }
        }]
      }
      networkProfile: {
        networkInterfaces: [
          {
            properties: {
              primary: true
            }
            id: SQLnic.id
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
          storageUri: SQLdiagsAccount.properties.primaryEndpoints.blob
        }
      }
    }
  }
  
  resource SQLdiagsAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
    name: SQLdiagStorageAccountName
    location: location
    sku: {
      name: 'Standard_LRS'
    }
    kind: 'Storage'
  }

  var diskConfigurationType = 'NEW'
  param storageWorkloadType string = 'General'
  param sqlDataDisksCount int = 1
  param dataPath string = 'F:\\SQLData'
  param sqlLogDisksCount int = 1
  param logPath string = 'G:\\SQLLog'

  var dataDisksLuns = range(0, sqlDataDisksCount)
  var logDisksLuns = range(sqlDataDisksCount, sqlLogDisksCount)
  var dataDisks = {
  createOption: 'Empty'
  caching: 'ReadOnly'
  writeAcceleratorEnabled: false
  storageAccountType: 'Premium_LRS'
  diskSizeGB: 128
  }
  var tempDbPath = 'D:\\SQLTemp'

  resource sqlVirtualMachine 'Microsoft.SqlVirtualMachine/sqlVirtualMachines@2022-07-01-preview' = {
    name: SQLname
    location: location
    properties: {
      virtualMachineResourceId: SQLvm.id
      sqlManagement: 'Full'
      sqlServerLicenseType: 'PAYG'
      storageConfigurationSettings: {
        diskConfigurationType: diskConfigurationType
        storageWorkloadType: storageWorkloadType
        sqlDataSettings: {
          luns: dataDisksLuns
          defaultFilePath: dataPath
        }
        sqlLogSettings: {
          luns: logDisksLuns
          defaultFilePath: logPath
        }
        sqlTempDbSettings: {
          defaultFilePath: tempDbPath
        }
      }
    }
 }

/////////////////////////////
///
///   Add SQL to Backup
///
/////////////////////////////

var backupFabric = 'Azure'
var protectionContainerSQL = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${SQLname}'
var protectedItemSQL = 'vm;iaasvmcontainerv2;${resourceGroup().name};${SQLname}'
param vaultName_var string
param vaultName_policyName string

resource vaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2020-02-02' = {
  name: '${vaultName_var}/${backupFabric}/${protectionContainerSQL}/${protectedItemSQL}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: vaultName_policyName
    sourceResourceId: SQLvm.id
  }
  dependsOn: [
  ]
}
