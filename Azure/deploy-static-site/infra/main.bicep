// main.bicep
// Orchestrates deployment of VNets, VMs, Load Balancer, Firewall, and Storage

param location1 string = 'East US'
param location2 string = 'East US 2'

module vnets 'vnets.bicep' = {
  name: 'vnetDeployment'
  params: {
    location1: location1
    location2: location2
  }
}

module lb 'loadbalancer.bicep' = {
  name: 'lbDeployment'
  dependsOn: [vnets]
  params: {
    location1: location1
  }
}

module vms 'vms.bicep' = {
  name: 'vmDeployment'
  dependsOn: [vnets, lb]
  params: {
    location1: location1
    location2: location2
    backendPoolId: lb.outputs.backendPoolId // Pass the load balancer backend pool ID
  }
}

module firewall 'firewall.bicep' = {
  name: 'firewallDeployment'
  dependsOn: [vnets]
  params: {
    location2: location2
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'eastuszrsstorage'
  location: location1
  sku: {
    name: 'Standard_LRS' // Updated to comply with allowed storage account types
  }
  kind: 'StorageV2'
}

module storage 'storage.bicep' = {
  name: 'storageDeployment'
  dependsOn: [vnets]
}
