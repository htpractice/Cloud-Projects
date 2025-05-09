param location1 string
param location2 string

// NSG for webSubnet in EastUS VNet
resource webSubnetNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'webSubnetNSG'
  location: location1
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
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
    ]
  }
}

// NSG for backendSubnet in EastUS2 VNet
resource backendSubnetNSG 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'backendSubnetNSG'
  location: location2
  properties: {
    securityRules: [
      {
        name: 'AllowRDP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
