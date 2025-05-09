// lb.bicep: Load Balancer Configuration

param location string
param lbName string

// Public IP Resource (Created dynamically within this file)
resource publicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'webServerPublicIP'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static' // Static allocation for Standard SKU
  }
}

// Load Balancer Resource
resource lb 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: lbName
  location: location
  sku: {
    name: 'Standard' // Standard SKU for high availability
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'loadBalancerFrontend'
        properties: {
          publicIPAddress: {
            id: publicIP.id // Dynamically reference the public IP created above
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'backendPool'
      }
    ]
  }
}

// Load Balancing Rule (Reference the frontendIPConfigurations and backendAddressPools via lb.properties)
resource loadBalancingRule 'Microsoft.Network/loadBalancers/loadBalancingRules@2023-04-01' = {
  parent: lb
  name: 'httpRule'
  properties: {
    frontendIPConfiguration: {
      id: lb.properties.frontendIPConfigurations[0].id
    }
    backendAddressPool: {
      id: lb.properties.backendAddressPools[0].id
    }
    protocol: 'Tcp'
    frontendPort: 80
    backendPort: 80
    enableFloatingIP: false
    idleTimeoutInMinutes: 4
    loadDistribution: 'Default'
  }
}

// Outputs
output lbId string = lb.id
output frontendIPConfigId string = lb.properties.frontendIPConfigurations[0].id
output backendPoolId string = lb.properties.backendAddressPools[0].id
output loadBalancingRuleId string = loadBalancingRule.id
output publicIpId string = publicIP.id // Output the public IP ID for reference
