// Task 1: Virtual Network Setup for Azure Capstone Project

// Parameters
param location1 string
param location2 string
param vnetPrefix1 string
param vnetPrefix2 string
param webSubnetPrefix string
param backendSubnetPrefix string
param GatewaySubnet1Prefix string
param GatewaySubnet2Prefix string
param AzureFirewallSubnetPrefix string
param vnetName1 string
param vnetName2 string
// EastUS VNet
resource eastUSVNet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName1
  location: location1
  properties: {
    addressSpace: {
      addressPrefixes: [vnetPrefix1]
    }
    subnets: [
      {
        name: 'webSubnet'
        properties: {
          addressPrefix: webSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: GatewaySubnet1Prefix // Ensure at least a /27 subnet
        }
      }
    ]
  }
}

// EastUS2 VNet
resource eastUS2VNet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName2
  location: location2
  properties: {
    addressSpace: {
      addressPrefixes: [vnetPrefix2]
    }
    subnets: [
      {
        name: 'backendSubnet'
        properties: {
          addressPrefix: backendSubnetPrefix
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: GatewaySubnet2Prefix // Ensure at least a /27 subnet
        }
      }
      {
        name: 'AzureFirewallSubnet' // Add this subnet for the firewall
        properties: {
          addressPrefix: AzureFirewallSubnetPrefix  // Ensure this does not overlap with other subnets
        }
      }
    ]
  }
}

// VNet Peering from EastUS to EastUS2
resource vnetPeering1 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: '${vnetName1}-to-${vnetName2}'
  parent: eastUSVNet
  properties: {
    remoteVirtualNetwork: {
      id: eastUS2VNet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// VNet Peering from EastUS2 to EastUS
resource vnetPeering2 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: '${vnetName2}-to-${vnetName1}'
  parent: eastUS2VNet
  properties: {
    remoteVirtualNetwork: {
      id: eastUSVNet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: false
  }
}

// Outputs
output eastUSVNetId string = eastUSVNet.id
output eastUS2VNetId string = eastUS2VNet.id
output vnetName1 string = eastUSVNet.name
output vnetName2 string = eastUS2VNet.name
output peering1Id string = vnetPeering1.id
output peering2Id string = vnetPeering2.id
output webSubnetId string = eastUSVNet.properties.subnets[0].id
output backendSubnetId string = eastUS2VNet.properties.subnets[0].id
output firewallSubnetId string = eastUS2VNet.properties.subnets[1].id

