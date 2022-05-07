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
param vnetHub object
param vmWeb object
param vmData object
param vmAD object
param vmAdmin string
param vmPassword string

/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////        NETWORK        /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource publicIpLb 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-lb'
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
    '3'
    '2'
    '1'
  ]
}

resource publicIpVmDt 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-vmdt'
  location: location
  tags: tags
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    idleTimeoutInMinutes: 4
    ipTags: []
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    deleteOption: 'Delete'
  }
  zones: []
}

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

resource publicIpNatGw 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-natgw'
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

resource natGateway 'Microsoft.Network/natGateways@2021-05-01' = {
  name: 'natgw01'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIpNatGw.id
      }
    ]
  }
  zones: []
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
          natGateway: {
            id: natGateway.id
          }
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: vnetSpoke01.subnets[0].name
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
    allowGatewayTransit: true
    useRemoteGateways: false
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
    allowGatewayTransit: true
    useRemoteGateways: false
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
          publicIPAddress: {
            id: publicIpVmDt.id
          }
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



////////////////////////////////////////
////////////////////////////////////////
/////////                      /////////
///////// VIRTUAL MACHINE DATA /////////
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




/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
///////// VIRTUAL MACHINES WEB  /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource lbWeb 'Microsoft.Network/loadBalancers@2021-05-01' = {
  name: 'lb-web'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'ipConfig'
        properties: {
          publicIPAddress: {
            id: publicIpLb.id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'inbound-http'
        properties: {
          backendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'lb-web', 'backendPool')
            }
          ]
          backendPort: 80
          disableOutboundSnat: true
          enableFloatingIP: false
          enableTcpReset: false
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'lb-web', 'ipConfig')
          }
          frontendPort: 80
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'lb-web', 'health-check')
          }
          protocol: 'Tcp'
        }
      }
    ]
    probes: [
      {
        name: 'health-check'
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
    name: 'backendPool'
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

var scriptIIS = '''
Install-Windowsfeature -Name Web-Server -IncludeManagementTools

Remove-Item C:\inetpub\wwwroot\iisstart.htm

Add-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value $("TFTEC AZ-700 - $($env:computername)")
'''

resource runCommands 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = [for i in range(0, vmWeb.count): {
  name: '${vmsWeb[i].name}-extension-IIS'
  location: location
  tags: tags
  dependsOn: [
    vmsWeb[i]
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

// var mountStorageDrive = format('''
// $connectTestResult = Test-NetConnection -ComputerName {2}.file.{0} -Port 445
// if ($connectTestResult.TcpTestSucceeded) {
//     cmd.exe /C "cmdkey /add:`"{2}.file.{0}`" /user:`"localhost\{2}`" /pass:`"{1}`""
//     New-PSDrive -Name Z -PSProvider FileSystem -Root "\\{2}.file.{0}\share" -Persist
// } else {
//     Write-Error -Message "Unable to reach the Azure storage account via port 445. Check to make sure your organization or ISP is not blocking port 445, or use Azure P2S VPN, Azure S2S VPN, or Express Route to tunnel SMB traffic over a different port."
// }
// ''', environment().suffixes.storage, storage.listKeys().keys[0].value, storage.name)

// resource runCommandsMountDriveWeb 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = [for i in range(0, vmWeb.count): {
//   name: '${vmsWeb[i].name}-extension-drive'
//   location: location
//   tags: tags
//   dependsOn: [
//     vmsWeb[i]
//   ]
//   parent: vmsWeb[i]
//   properties: {
//     asyncExecution: true
//     source: {
//       script: mountStorageDrive
//     }
//     timeoutInSeconds: 180
//   }
// } ]

// resource runCommandsMountDriveData 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
//   name: '${vmDataDeploy.name}-extension-drive'
//   location: location
//   tags: tags
//   parent: vmDataDeploy
//   properties: {
//     asyncExecution: true
//     source: {
//       script: mountStorageDrive
//     }
//     timeoutInSeconds: 180
//   }
// }

// resource runCommandsMountDriveAD 'Microsoft.Compute/virtualMachines/runCommands@2021-11-01' = {
//   name: '${vmAdDeploy.name}-extension-drive'
//   location: location
//   tags: tags
//   parent: vmAdDeploy
//   properties: {
//     asyncExecution: true
//     source: {
//       script: mountStorageDrive
//     }
//     timeoutInSeconds: 180
//   }
// }
