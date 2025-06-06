// vnets.bicep
// Creates two VNets and establishes peering between them

param location1 string
param location2 string

resource vnet1 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'EastUS-VNet'
  location: location1
  properties: {
    addressSpace: {
      addressPrefixes: ['10.0.0.0/16']
    }
    subnets: [{
      name: 'webSubnet'
      properties: {
        addressPrefix: '10.0.0.0/24'
        networkSecurityGroup: {
          id: webSubnetNsg.outputs.nsgId
        }
      }
    }]
  }
}

resource vnet2 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: 'EastUS2-VNet'
  location: location2
  properties: {
    addressSpace: {
      addressPrefixes: ['10.1.0.0/16']
    }
    subnets: [
      {
        name: 'wsSubnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet' // Add the missing AzureFirewallSubnet
        properties: {
          addressPrefix: '10.1.1.0/24'
          // AzureFirewallSubnet cannot have an NSG attached
        }
      }
    ]
  }
}

resource vnet1ToVnet2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'vnet1ToVnet2'
  parent: vnet1
  properties: {
    remoteVirtualNetwork: {
      id: vnet2.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

resource vnet2ToVnet1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'vnet2ToVnet1'
  parent: vnet2
  properties: {
    remoteVirtualNetwork: {
      id: vnet1.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

module webSubnetNsg 'nsg.bicep' = {
  name: 'webSubnetNsgDeployment'
  params: {
    nsgName: 'webSubnetNsg'
    location: location1
    securityRules: [
      {
        name: 'AllowHttp'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          priority: 200
          direction: 'Inbound'
          access: 'Deny'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

// Removed azureFirewallSubnetNsg module since AzureFirewallSubnet cannot have an NSG attached

// NSG associations are now defined directly in the subnet properties
