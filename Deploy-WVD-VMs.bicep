//////////////////////////////////////////////////
///
///  Define WVD parameters
///
/////////////////////////////////////////////////

param hostpoolName string
param hostpoolFriendlyName string
param appgroupName string
param appgroupNameFriendlyName string
param workspaceName string
param workspaceNameFriendlyName string
param applicationgrouptype string = 'Desktop'
param preferredAppGroupType string = 'Desktop'
param wvdbackplanelocation string = 'northeurope'
param hostPoolType string = 'pooled'
param loadBalancerType string = 'BreadthFirst'
param maxSessionLimit int = 99999
param tokenExpirationTime string
//////////////////////////////////////////////////
///
///  WVD Hostpool Creation
///
/////////////////////////////////////////////////

resource hp 'Microsoft.DesktopVirtualization/hostpools@2019-12-10-preview' = {
  name: hostpoolName
  location: wvdbackplanelocation
  properties: {
    friendlyName: hostpoolFriendlyName
    hostPoolType : hostPoolType
    loadBalancerType : loadBalancerType
    preferredAppGroupType: preferredAppGroupType
    maxSessionLimit: maxSessionLimit
    validationEnvironment: false
    registrationInfo: {
      expirationTime: tokenExpirationTime
      token: null
      registrationTokenOperation: 'Update'
    }
  }
}



//////////////////////////////////////////////////
///
///  WVD Appgroup Creation
///
/////////////////////////////////////////////////

resource ag 'Microsoft.DesktopVirtualization/applicationgroups@2019-12-10-preview' = {
  name: appgroupName
  location: wvdbackplanelocation
  properties: {
      friendlyName: appgroupNameFriendlyName
      applicationGroupType: applicationgrouptype
      hostPoolArmPath: hp.id
    }
  }

//////////////////////////////////////////////////
///
///  WVD Workspace Creation
///
/////////////////////////////////////////////////

resource ws 'Microsoft.DesktopVirtualization/workspaces@2019-12-10-preview' = {
  name: workspaceName
  location: wvdbackplanelocation
  properties: {
      friendlyName: workspaceNameFriendlyName
      applicationGroupReferences: [
        ag.id
      ]
  }
}


