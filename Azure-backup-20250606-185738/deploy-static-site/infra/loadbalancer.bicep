// loadbalancer.bicep
// Creates a load balancer for w1 and w2
param location1 string

resource lb 'Microsoft.Network/loadBalancers@2023-04-01' = {
  name: 'webLb'
  location: location1
  sku: {
    name: 'Basic'
  }
  properties: {
    frontendIPConfigurations: [{
      name: 'LoadBalancerFrontEnd'
      properties: {
        privateIPAllocationMethod: 'Dynamic'
        subnet: {
          id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'EastUS-VNet', 'webSubnet')
        }
      }
    }]
    backendAddressPools: [{ name: 'backendPool' }]
    loadBalancingRules: [
      {
        name: 'httpRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', 'webLb', 'LoadBalancerFrontEnd')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'webLb', 'backendPool')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          enableFloatingIP: false
          idleTimeoutInMinutes: 4
          loadDistribution: 'Default'
          probe: {
            id: resourceId('Microsoft.Network/loadBalancers/probes', 'webLb', 'httpProbe')
          }
        }
      }
    ]
    probes: [{
      name: 'httpProbe'
      properties: {
        protocol: 'Http'
        port: 80
        requestPath: '/'
        intervalInSeconds: 5
        numberOfProbes: 2
      }
    }]
  }
}

// Output the backend pool ID for reference in the VM NIC
output backendPoolId string = resourceId('Microsoft.Network/loadBalancers/backendAddressPools', lb.name, 'backendPool')
