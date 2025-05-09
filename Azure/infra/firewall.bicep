param location string
param firewallName string = 'eastUS2Firewall'
param vnetId string
param subnetName string = 'AzureFirewallSubnet'
param firewallPublicIPId string

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
            id: firewallPublicIPId // Associate the public IP with the firewall
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

output firewallId string = firewall.id
