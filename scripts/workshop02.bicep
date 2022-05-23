/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////  CONFIGURAÇÕES GERAIS /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

param location string = resourceGroup().location
param tags object
param vnetSpoke01 object
param vnetSpoke02 object
param vnetSpoke03 object
param vnetHub object
param vnetOnpremise object
param vmWeb object
param vmData object
param vmAD object
param vmFW object
param vmClient object
param onPremRouteTable object
param vmAdmin string
param vmPassword string

/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////     ON-PREMISES RG    /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

// resource onPremRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
//   name: 'rg-contoso'
//   location: 'westus2'
//   scope: 'subscription'
// }



/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////      ROUTE TABLES     /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource onPremRouteTableDeploy 'Microsoft.Network/routeTables@2021-08-01' = {
  name: onPremRouteTable.name
  location: onPremRouteTable.location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'route-${vnetHub.name}'
        properties: {
          addressPrefix: vnetHub.addressPrefix
          hasBgpOverride: false
          nextHopIpAddress: vmFW.privateIP
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'route-${vnetSpoke01.name}'
        properties: {
          addressPrefix: vnetSpoke01.addressPrefix
          hasBgpOverride: false
          nextHopIpAddress: vmFW.privateIP
          nextHopType: 'VirtualAppliance'
        }
      }
      {
        name: 'route-${vnetSpoke02.name}'
        properties: {
          addressPrefix: vnetSpoke02.addressPrefix
          hasBgpOverride: false
          nextHopIpAddress: vmFW.privateIP
          nextHopType: 'VirtualAppliance'
        }
      }
    ]
  }
}




/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////        NETWORK        /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource publicIpBastion 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-bastion'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    idleTimeoutInMinutes: 4
    ipTags: []
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Delete'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
}

resource nsgDataDeploy 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: vnetSpoke02.nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource nsgAdDeploy 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: vnetHub.nsgName
  location: location
  tags: tags
  properties: {
    securityRules: []
  }
}

resource asgWeb 'Microsoft.Network/applicationSecurityGroups@2021-05-01' = {
  name: 'asg-web'
  location: location
  tags: tags
}

resource nsgWebDeploy 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: vnetSpoke01.nsgName
  location: location
  tags: tags
}

resource nsgWebAppDeploy 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: vnetSpoke03.nsgName
  location: 'centralus'
  tags: tags
}

resource vnetSpoke01Deploy 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetSpoke01.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpoke01.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetSpoke01.subnets[0].name
        properties: {
          addressPrefix: vnetSpoke01.subnets[0].addressPrefix
          networkSecurityGroup: {
            id: nsgWebDeploy.id
          }
        }
      }
      {
        name: vnetSpoke01.subnets[1].name
        properties: {
          addressPrefix: vnetSpoke01.subnets[1].addressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgWebDeploy.id
          }
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: vnetSpoke01.subnets[0].name
  }

  resource subnetWebApp 'subnets' existing = {
    name: vnetSpoke01.subnets[1].name
  }
}

resource vnetSpoke02Deploy 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetSpoke02.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpoke02.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetSpoke02.subnets[0].name
        properties: {
          addressPrefix: vnetSpoke02.subnets[0].addressPrefix
          networkSecurityGroup: {
            id: nsgDataDeploy.id
          }
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: vnetSpoke02.subnets[0].name
  }
}

resource vnetSpoke03Deploy 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetSpoke03.name
  location: vnetSpoke03.location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSpoke03.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetSpoke03.subnets[0].name
        properties: {
          addressPrefix: vnetSpoke03.subnets[0].addressPrefix
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
          networkSecurityGroup: {
            id: nsgWebAppDeploy.id
          }
        }
      }
    ]
  }

  resource subnetWebApp 'subnets' existing = {
    name: vnetSpoke03.subnets[0].name
  }
}

resource vnetHubDeploy 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetHub.name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetHub.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetHub.subnets[0].name
        properties: {
          addressPrefix: vnetHub.subnets[0].addressPrefix
          networkSecurityGroup: {
            id: nsgAdDeploy.id
          }
        }
      }
      {
        name: vnetHub.subnets[1].name
        properties: {
          addressPrefix: vnetHub.subnets[1].addressPrefix
        }
      }
    ]
  }

  resource subnetSrv 'subnets' existing = {
    name: vnetHub.subnets[0].name
  }

  resource subnetBastion 'subnets' existing = {
    name: vnetHub.subnets[1].name
  }
}

resource vnetOnpremiseDeploy 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetOnpremise.name
  location: vnetOnpremise.location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetOnpremise.addressPrefix
      ]
    }
    subnets: [
      {
        name: vnetOnpremise.subnets[0].name
        properties: {
          addressPrefix: vnetOnpremise.subnets[0].addressPrefix
          routeTable: {
            id: onPremRouteTableDeploy.id
          }
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: vnetOnpremise.subnets[0].name
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2021-05-01' = {
  name: 'bastion01'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: false
    enableFileCopy: true
    enableIpConnect: false
    enableShareableLink: false
    enableTunneling: false
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIpBastion.id
          }
          subnet: {
            id: vnetHubDeploy::subnetBastion.id
          }
        }
      }
    ]
    scaleUnits: 2
  }
}

resource vnetSpoke01PeeringHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetSpoke01Deploy
  name: '${vnetSpoke01Deploy.name}-${vnetHubDeploy.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false // true
    remoteVirtualNetwork: {
      id: vnetHubDeploy.id
    }
  }
}

resource vnetSpoke02PeeringHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetSpoke02Deploy
  name: '${vnetSpoke02Deploy.name}-${vnetHubDeploy.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false // true
    remoteVirtualNetwork: {
      id: vnetHubDeploy.id
    }
  }
}

resource vnetHubPeeringSpoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetHubDeploy
  name: '${vnetHubDeploy.name}-${vnetSpoke01Deploy.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke01Deploy.id
    }
  }
}

resource vnetHubPeeringSpoke02 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetHubDeploy
  name: '${vnetHubDeploy.name}-${vnetSpoke02Deploy.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke02Deploy.id
    }
  }
}


//////////////////////////////////////////
//////////////////////////////////////////
/////////                        /////////
/////////        SCRIPTS         /////////
/////////                        /////////
//////////////////////////////////////////
//////////////////////////////////////////

var scriptIIS = '''
Install-Windowsfeature -Name Web-Server -IncludeManagementTools

Remove-Item C:\inetpub\wwwroot\iisstart.htm

Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("TFTEC AZ-700 - $($env:computername)")
'''

var scriptDisableWindowsFirewall = '''
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
'''


//////////////////////////////////////////
//////////////////////////////////////////
/////////                        /////////
///////// VIRTUAL MACHINES DATA  /////////
/////////                        /////////
//////////////////////////////////////////
//////////////////////////////////////////

resource nicData 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: vmData.nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetSpoke02Deploy::subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmDataDeploy 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmData.name
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmWeb.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmData.diskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicData.id
        }
      ]
    }
    osProfile: {
      computerName: vmData.name
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
  }
}

resource runCommandsFirewallData 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
  name: '${vmDataDeploy.name}-disable-firewall'
  location: location
  tags: tags
  parent: vmDataDeploy
  properties: {
    asyncExecution: true
    source: {
      script: scriptDisableWindowsFirewall
    }
    timeoutInSeconds: 180
  }
}


////////////////////////////////////////
////////////////////////////////////////
/////////                      /////////
/////////  VIRTUAL MACHINE AD  /////////
/////////                      /////////
////////////////////////////////////////
////////////////////////////////////////

resource nicAd 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: vmAD.nicName
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetHubDeploy::subnetSrv.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmAdDeploy 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmAD.name
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmAD.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmAD.diskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicAd.id
        }
      ]
    }
    osProfile: {
      computerName: vmAD.name
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
  }
}

resource runCommandsFirewallAD 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
  name: '${vmAdDeploy.name}-disable-firewall'
  location: location
  tags: tags
  parent: vmAdDeploy
  properties: {
    asyncExecution: true
    source: {
      script: scriptDisableWindowsFirewall
    }
    timeoutInSeconds: 180
  }
}



/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
///////// VIRTUAL MACHINES WEB  /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource lbWeb 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: vmWeb.loadBalancer.Name
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    backendAddressPools: [
      {
        name: vmWeb.loadBalancer.backendPoolName
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          privateIPAddressVersion:'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vnetSpoke01Deploy::subnet.id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: vmWeb.loadBalancer.inboudRuleName
        properties: {
          backendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', vmWeb.loadBalancer.Name, vmWeb.loadBalancer.backendPoolName)
            }
          ]
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', vmWeb.loadBalancer.Name, 'ipConfig')
          }
          frontendPort: 80
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', vmWeb.loadBalancer.Name, vmWeb.loadBalancer.probeName)
          }
          protocol: 'Tcp'
        }
      }
    ]
    probes: [
      {
        name: vmWeb.loadBalancer.probeName
        properties: {
          intervalInSeconds: 5
          numberOfProbes: 2
          port: 80
          protocol: 'Http'
          requestPath: '/'
        }
      }
    ]
  }

  resource backendPool 'backendAddressPools' existing = {
    name: vmWeb.loadBalancer.backendPoolName
  }
}

resource nicsWeb 'Microsoft.Network/networkInterfaces@2021-03-01' = [for i in range(1, vmWeb.count): {
  name: '${vmWeb.nicName}0${i}'
  location: location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetSpoke01Deploy::subnet.id
          }
          applicationSecurityGroups: [
            {
              id: asgWeb.id
            }
          ]
          loadBalancerBackendAddressPools: [
            {
              id: lbWeb::backendPool.id
            }
          ]
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
} ]

resource securityRuleHttp 'Microsoft.Network/networkSecurityGroups/securityRules@2021-05-01' = {
  name: 'Allow-Http'
  parent: nsgWebDeploy
  properties: {
    access: 'Allow'
    description: 'Allow HTTP traffic to web servers'
    destinationApplicationSecurityGroups: [
      {
        id: asgWeb.id
      }
    ]
    destinationPortRange: '80'
    direction: 'Inbound'
    priority: 200
    protocol: 'Tcp'
    sourceAddressPrefix: '*'
    sourcePortRange: '*'
  }
}

resource vmsWeb 'Microsoft.Compute/virtualMachines@2021-11-01' = [for i in range(1, vmWeb.count): {
  name: '${vmWeb.name}0${i}'
  location: location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmWeb.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmWeb.diskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicsWeb[i - 1].id
        }
      ]
    }
    osProfile: {
      computerName: '${vmWeb.name}0${i}'
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
  }
} ]

resource runCommandsFirewallWeb 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = [for i in range(0, vmWeb.count): {
  name: '${vmsWeb[i].name}-disable-firewall'
  location: location
  tags: tags
  dependsOn: [
    vmsWeb
  ]
  parent: vmsWeb[i]
  properties: {
    asyncExecution: true
    source: {
      script: scriptDisableWindowsFirewall
    }
    timeoutInSeconds: 180
  }
} ]

resource runCommands 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = [for i in range(0, vmWeb.count): {
  name: '${vmsWeb[i].name}-extension-IIS'
  location: location
  tags: tags
  dependsOn: [
    vmsWeb
  ]
  parent: vmsWeb[i]
  properties: {
    asyncExecution: true
    source: {
      script: scriptIIS
    }
    timeoutInSeconds: 180
  }
} ]


////////////////////////////////////////
////////////////////////////////////////
/////////                      /////////
/////////  VIRTUAL MACHINE FW  /////////
/////////                      /////////
////////////////////////////////////////
////////////////////////////////////////

resource nicFw 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: vmFW.nicName
  location: vmFW.location
  tags: tags
  properties: {
    enableIPForwarding: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetOnpremiseDeploy::subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vmFW.privateIP
        }
      }
    ]
  }
}

resource vmFwDeploy 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmFW.name
  location: vmFW.location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmFW.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmFW.diskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-datacenter'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicFw.id
        }
      ]
    }
    osProfile: {
      computerName: vmFW.name
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
  }
}

resource runCommandsFirewallFW 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
  name: '${vmFwDeploy.name}-disable-firewall'
  location: vmFW.location
  tags: tags
  parent: vmFwDeploy
  properties: {
    asyncExecution: true
    source: {
      script: scriptDisableWindowsFirewall
    }
    timeoutInSeconds: 180
  }
}



////////////////////////////////////////////
////////////////////////////////////////////
/////////                          /////////
/////////  VIRTUAL MACHINE CLIENT  /////////
/////////                          /////////
////////////////////////////////////////////
////////////////////////////////////////////

resource nicClient 'Microsoft.Network/networkInterfaces@2021-03-01' = {
  name: vmClient.nicName
  location: vmClient.location
  tags: tags
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnetOnpremiseDeploy::subnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource vmClientDeploy 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmClient.name
  location: vmClient.location
  tags: tags
  properties: {
    hardwareProfile: {
      vmSize: vmClient.size
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: vmClient.diskType
        }
      }
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-21h2-pro'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicClient.id
        }
      ]
    }
    osProfile: {
      computerName: vmClient.name
      adminUsername: vmAdmin
      adminPassword: vmPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
  }
}

resource runCommandsFirewallClient 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
  name: '${vmClientDeploy.name}-disable-firewall'
  location: vmClient.location
  tags: tags
  parent: vmClientDeploy
  properties: {
    asyncExecution: true
    source: {
      script: scriptDisableWindowsFirewall
    }
    timeoutInSeconds: 180
  }
}



/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////        WEB APPS       /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////


resource asp01Deploy 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: 'asp-webapp01'
  location: 'centralus'
  tags: tags
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    elasticScaleEnabled: false
    reserved: true
    zoneRedundant: false
  }
}

resource asp02Deploy 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: 'asp-webapp02'
  location: location
  tags: tags
  sku: {
    name: 'S1'
  }
  kind: 'linux'
  properties: {
    elasticScaleEnabled: false
    reserved: true
    zoneRedundant: false
  }
}

resource webApp01Deploy 'Microsoft.Web/sites@2021-03-01' = {
  name: 'webapp-${uniqueString(subscription().subscriptionId)}-01'
  location: 'centralus'
  tags: tags
  properties: {
    clientAffinityEnabled: false
    clientCertEnabled: false
    enabled: true
    hostNamesDisabled: false
    httpsOnly: true
    reserved: true
    serverFarmId: asp01Deploy.id
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      http20Enabled: false
      ipSecurityRestrictions: [
        {
          action: 'Allow'
          description: 'Allow FrontDoor connections'
          name: 'Allow-FrontDoor'
          priority: 300
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          // headers: {
          //   'X-Azure-FDID': [
          //     '1234' //<FrontDoor ID>
          //   ]
          // }
        }
      ]
      linuxFxVersion: 'DOTNETCORE|6.0'
      use32BitWorkerProcess: false
    }
  }
}

resource webApp02Deploy 'Microsoft.Web/sites@2021-03-01' = {
  name: 'webapp-${uniqueString(subscription().subscriptionId)}-02'
  location: location
  tags: tags
  properties: {
    clientAffinityEnabled: false
    clientCertEnabled: false
    enabled: true
    hostNamesDisabled: false
    httpsOnly: true
    reserved: true
    serverFarmId: asp02Deploy.id
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
      http20Enabled: false
      ipSecurityRestrictions: [
        {
          action: 'Allow'
          description: 'Allow FrontDoor connections'
          name: 'Allow-FrontDoor'
          priority: 300
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          // headers: {
          //   'X-Azure-FDID': [
          //     '1234' //<FrontDoor ID>
          //   ]
          // }
        }
      ]
      linuxFxVersion: 'DOTNETCORE|6.0'
      use32BitWorkerProcess: false
    }
  }
}

resource webApp01NetworkDeploy 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  name: 'virtualNetwork'
  parent: webApp01Deploy
  properties: {
    subnetResourceId: vnetSpoke03Deploy::subnetWebApp.id
    swiftSupported: true
  }
}

resource webApp02NetworkDeploy 'Microsoft.Web/sites/networkConfig@2021-03-01' = {
  name: 'virtualNetwork'
  parent: webApp02Deploy
  properties: {
    subnetResourceId: vnetSpoke01Deploy::subnetWebApp.id
    swiftSupported: true
  }
}

/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////    AZURE RESOURCES    /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////


resource storage 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: 'stolab${uniqueString(subscription().subscriptionId)}'
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    publicNetworkAccess: 'Disabled'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    allowCrossTenantReplication: false
    defaultToOAuthAuthentication: false
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: []
    }
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        queue: {
          enabled: true
        }
        table: {
          enabled: true
        }
      }
    }
    routingPreference: {
      publishInternetEndpoints: false
      publishMicrosoftEndpoints: false
      routingChoice: 'MicrosoftRouting'
    }
  }
}

resource fileService 'Microsoft.Storage/storageAccounts/fileServices@2021-08-01' = {
  name: 'default'
  parent: storage
  properties: {
    shareDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource share 'Microsoft.Storage/storageAccounts/fileServices/shares@2021-08-01' = {
  name: 'share'
  parent: fileService
  properties: {
    accessTier: 'Hot'
    enabledProtocols: 'SMB'
    shareQuota: 1024
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: 'pvtsto'
  location: location
  tags: tags
  properties: {
    privateLinkServiceConnections: [
      {
        name: 'pvtsto'
        properties: {
          groupIds: [
            'file'
          ]
          privateLinkServiceId: storage.id
        }
      }
    ]
    subnet: {
      id: vnetHubDeploy::subnetSrv.id
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${environment().suffixes.storage}'
  location: 'global'
}

resource privateDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: 'default'
  parent: privateEndpoint
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-core-net'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

resource vnetHubDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-to-${toLower(vnetHubDeploy.name)}'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetHubDeploy.id
    }
  }
}

resource vnetSpoke01DnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-to-${toLower(vnetSpoke01Deploy.name)}'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetSpoke01Deploy.id
    }
  }
}

resource vnetSpoke02DnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'link-to-${toLower(vnetSpoke02Deploy.name)}'
  location: 'global'
  tags: tags
  parent: privateDnsZone
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetSpoke02Deploy.id
    }
  }
}

