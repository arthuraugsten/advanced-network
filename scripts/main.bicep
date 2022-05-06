/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////  CONFIGURAÇÕES GERAIS /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////


param location string = resourceGroup().location

var TAGS = {
  Laboratio: 'LAB-REDES'
}



/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////        NETWORK        /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////

resource publicIpILB 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'pip-lb'
  location: location
  tags: TAGS
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    idleTimeoutInMinutes: 4
    ipTags: []
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
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
  tags: TAGS
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    idleTimeoutInMinutes: 4
    ipTags: []
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  zones: []
}

resource vnetSpoke01 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-spoke01'
  location: location
  tags: TAGS
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.10.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'sub-websrv'
        properties: {
          addressPrefix: '10.10.1.0/24'
        }
      }
    ]
  }

  resource subnet 'subnets' existing = {
    name: 'sub-websrv'
  }
}

resource vnetSpoke02 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-spoke02'
  location: location
  tags: TAGS
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'sub-datasrv'
        properties: {
          addressPrefix: '172.16.1.0/24'
        }
      }
    ]
    networkSecurityGroup: {
      id: 'nsg-data'
      location: location
      properties: {
        securityRules: [
          {
            name: 'Allow-RDP'
            properties: {
              access: 'string'
              description: 'Allow RDP Traffic'
              destinationAddressPrefix: publicIpVmDt.identity
              destinationPortRange: 'Any'
              //direction: 'string'
              priority: 100
              protocol: 'RDP'
              sourceAddressPrefix: 'Any'
              sourcePortRange: '3389'
            }
            type: 'string'
          }
        ]
      }
      tags: TAGS
    }
  }

  resource subnet 'subnets' existing = {
    name: 'sub-datasrv'
  }
}

resource vnetHub 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: 'vnet-hub'
  location: location
  tags: TAGS
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'sub-hub'
        properties: {
          addressPrefix: '192.168.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '192.168.250.0/24'
        }
      }
    ]
  }

  resource subnetHub 'subnets' existing = {
    name: 'sub-hub'
  }

  resource subnetBastion 'subnets' existing = {
    name: 'AzureBastionSubnet'
  }
}

resource vnetSpoke01PeeringHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetSpoke01
  name: '${vnetSpoke01.name}-${vnetHub.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource vnetSpoke02PeeringHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetSpoke02
  name: '${vnetSpoke02.name}-${vnetHub.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetHub.id
    }
  }
}

resource vnetHubPeeringSpoke01 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetHub
  name: '${vnetHub.name}-${vnetSpoke01.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke01.id
    }
  }
}

resource vnetHubPeeringSpoke02 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-05-01' = {
  parent: vnetHub
  name: '${vnetHub.name}-${vnetSpoke02.name}'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: vnetSpoke02.id
    }
  }
}





/////////////////////////////////////////
/////////////////////////////////////////
/////////                       /////////
/////////   VIRTUAL MACHINES    /////////
/////////                       /////////
/////////////////////////////////////////
/////////////////////////////////////////


