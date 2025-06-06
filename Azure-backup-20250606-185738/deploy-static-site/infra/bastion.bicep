// bastion.bicep
// Deploys Azure Bastion service for secure SSH and RDP access

@description('Location for the Bastion host')
param location string = 'eastus'

@description('Name of the VNet where Bastion will be deployed')
param vnetName string = 'EastUS-VNet'

@description('Name for the Bastion service')
param bastionHostName string = 'project-bastion'

// First, create a dedicated subnet for Bastion if it doesn't exist
resource bastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-04-01' = {
  name: '${vnetName}/AzureBastionSubnet'
  properties: {
    addressPrefix: '10.0.3.0/24' // Using a /24 subnet for Bastion (larger than minimum /27)
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Disabled'
  }
}

// Create a public IP for the Bastion host
resource bastionPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: '${bastionHostName}-pip'
  location: location
  sku: {
    name: 'Standard' // Standard SKU required for Bastion
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// Deploy the Bastion host
resource bastionHost 'Microsoft.Network/bastionHosts@2023-04-01' = {
  name: bastionHostName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableTunneling: true
    enableIpConnect: true
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: bastionSubnet.id
          }
          publicIPAddress: {
            id: bastionPublicIP.id
          }
        }
      }
    ]
  }
}

// Output the Bastion host resource ID
output bastionId string = bastionHost.id

