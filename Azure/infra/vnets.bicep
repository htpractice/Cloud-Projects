// Task 1: Virtual Network Setup for Azure Capstone Project

// Parameters
param location1 string = 'East US'
param location2 string = 'East US 2'
param vnetPrefix1 string = '10.0.0.0/16'
param vnetPrefix2 string = '10.1.0.0/16'
param subnetPrefix1 string = '10.0.1.0/24'
param subnetPrefix2 string = '10.1.1.0/24'
param vnetName1 string = 'EastUS-VNet'
param vnetName2 string = 'EastUS2-VNet'

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
          addressPrefix: subnetPrefix1
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
          addressPrefix: subnetPrefix2
        }
      }
      {
        name: 'AzureFirewallSubnet' // Add this subnet for the firewall
        properties: {
          addressPrefix: '10.1.2.0/24' // Ensure this does not overlap with other subnets
        }
      }
    ]
  }
}

// VPN Gateway for EastUS VNet
resource eastUSVpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: 'eastUSVpnGateway'
  location: location1
  properties: {
    ipConfigurations: [
      {
        name: 'vpnGatewayIpConfig'
        properties: {
          publicIPAddress: {
            id: eastUSPublicIP.id
          }
          subnet: {
            id: '${eastUSVNet.id}/subnets/GatewaySubnet'
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
    }
  }
}

// VPN Gateway for EastUS2 VNet
resource eastUS2VpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: 'eastUS2VpnGateway'
  location: location2
  properties: {
    ipConfigurations: [
      {
        name: 'vpnGatewayIpConfig'
        properties: {
          publicIPAddress: {
            id: eastUS2PublicIP.id
          }
          subnet: {
            id: '${eastUS2VNet.id}/subnets/GatewaySubnet'
          }
        }
      }
    ]
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    sku: {
      name: 'VpnGw1'
    }
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
output vnet1Id string = eastUSVNet.id
output vnet2Id string = eastUS2VNet.id
output peering1Id string = vnetPeering1.id
output peering2Id string = vnetPeering2.id
output webSubnetId string = eastUSVNet.properties.subnets[0].id
output backendSubnetId string = eastUS2VNet.properties.subnets[0].id
output vnet1Name string = eastUSVNet.name
output vnet2Name string = eastUS2VNet.name
