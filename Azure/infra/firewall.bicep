param location string
param firewallName string = 'eastUS2Firewall'
param vnetId string
param subnetName string = 'AzureFirewallSubnet'

// Create a Public IP Address for the Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${firewallName}-publicIP'
  location: location
  sku: {
    name: 'Standard' // Change to an allowed SKU (e.g., Basic or Standard)
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create the Azure Firewall
resource firewall 'Microsoft.Network/azureFirewalls@2023-04-01' = {
  name: firewallName
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'firewallIpConfig'
        properties: {
          subnet: {
            id: '${vnetId}/subnets/${subnetName}'
          }
          publicIPAddress: {
            id: firewallPublicIP.id // Associate the public IP with the firewall
          }
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
              name: 'denyFacebook'
              sourceAddresses: ['*']
              targetFqdns: ['facebook.com']
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
            }
          ]
        }
      }
    ]
  }
}
