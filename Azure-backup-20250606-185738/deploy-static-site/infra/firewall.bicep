// firewall.bicep
// Deploys Azure Firewall and configures a rule to block social media

param location2 string

resource fwPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'fw-pip'
  location: location2
  sku: {
    name: 'Standard'  // Azure Firewall requires Standard SKU
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: 'eastus2-firewall'
  location: location2
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'fwConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'EastUS2-VNet', 'AzureFirewallSubnet')
          }
          publicIPAddress: {
            id: fwPublicIP.id
          }
          privateIPAddress: '10.1.0.4' // Assign a static private IP address
        }
      }
    ]
    applicationRuleCollections: [
      {
        name: 'blockSocialMedia'
        properties: {
          priority: 100
          action: {
            type: 'Deny'
          }
          rules: [
            {
              name: 'blockSocial'
              targetFqdns: ['facebook.com', 'instagram.com', 'twitter.com']
              protocols: [
                {
                  port: 443
                  protocolType: 'Https'
                }
              ]
              sourceAddresses: ['*']
            }
          ]
        }
      }
    ]
  }
}
