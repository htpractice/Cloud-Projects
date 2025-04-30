// vms.bicep
// Deploys web VMs in availability set and a backend VM with restricted outbound access

param location1 string
param location2 string
param backendPoolId string = '' // Parameter for load balancer backend pool
@allowed([
  'Standard_B2ms'
  'Standard_B1ms'
  'Standard_B4ms'
  'Standard_D2_v3'
  'Standard_DS1_v2'
])
param allowedVmSize string = 'Standard_B2ms'

resource availSet 'Microsoft.Compute/availabilitySets@2023-03-01' = {
  name: 'webAvailSet'
  location: location1
  sku: {
    name: 'Aligned' // Updated to 'Aligned' SKU
  }
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
}

module w1Nsg 'nsg.bicep' = {
  name: 'w1NsgDeployment'
  params: {
    nsgName: 'w1Nsg'
    location: location1
    securityRules: [
      {
        name: 'AllowRdp'
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

resource w1Nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'w1Nic'
  location: location1
  properties: {
    networkSecurityGroup: {
      id: w1Nsg.outputs.nsgId
    }
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'EastUS-VNet', 'webSubnet')
          }
          privateIPAllocationMethod: 'Dynamic'
          loadBalancerBackendAddressPools: !empty(backendPoolId) ? [
            {
              id: backendPoolId
            }
          ] : []
        }
      }
    ]
  }
}

resource w1 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: 'w1'
  location: location1
  properties: {
    hardwareProfile: {
      vmSize: allowedVmSize // Updated to use the allowed VM size parameter
    }
    availabilitySet: {
      id: availSet.id
    }
    osProfile: {
      computerName: 'w1'
      adminUsername: 'azureuser'
      adminPassword: 'P@ssword1234!'
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        // Removed the managedDisk property to avoid storage account type modification
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: w1Nic.id
        }
      ]
    }
  }
}

// (w2 and WS11 VM definitions would go here with similar structure)

output w1NicId string = w1Nic.id // Output the ID of the w1Nic resource
