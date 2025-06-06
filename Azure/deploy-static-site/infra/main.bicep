// main.bicep
// Orchestrates deployment of VNets, VMs, Load Balancer, Firewall, and Storage

param location1 string = 'East US'
param location2 string = 'East US 2'

@description('SSH public key for Linux VM')
param sshPublicKey string

@allowed([
  'Standard_B2ms'
  'Standard_B1ms'
  'Standard_B4ms'
  'Standard_D2_v3'
  'Standard_DS1_v2'
])
param allowedVmSize string = 'Standard_B2ms'

module vnets 'vnets.bicep' = {
  name: 'vnetDeployment'
  params: {
    location1: location1
    location2: location2
  }
}

module storage 'storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location1: location1
    location2: location2
  }
}

module bastion 'bastion.bicep' = {
  name: 'bastionDeployment'
  dependsOn: [vnets]
  params: {
    location: location1
    vnetName: 'EastUS-VNet'
    bastionHostName: 'az-final-project-bastion'
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
    sshPublicKey: sshPublicKey
    allowedVmSize: allowedVmSize
  }
}

module firewall 'firewall.bicep' = {
  name: 'firewallDeployment'
  dependsOn: [vnets]
  params: {
    location2: location2
  }
}

// Outputs for important resources
output staticWebsiteUrl string = storage.outputs.staticWebsiteUrl
output primaryStorageName string = storage.outputs.primaryStorageName
output backupStorageName string = storage.outputs.backupStorageName
