// Deploy the Virtual Networks
module vnets './vnets.bicep' = {
  name: 'vnetsDeployment'
  params: {
    location1: 'East US'
    location2: 'East US 2'
    vnetPrefix1: '10.0.0.0/16'
    vnetPrefix2: '10.1.0.0/16'
    subnetPrefix1: '10.0.1.0/24'
    subnetPrefix2: '10.1.1.0/24'
    vnetName1: 'EastUS-VNet'
    vnetName2: 'EastUS2-VNet'
  }
}

// Deploy the Firewall (depends on vnets)
module firewall './firewall.bicep' = {
  name: 'firewallDeployment'
  params: {
    location: 'East US 2'
    vnetId: vnets.outputs.vnet2Id
  }
  dependsOn: [
    vnets // Ensure the virtual networks are deployed before the firewall
  ]
}

// Deploy the Virtual Machines (depends on vnets and firewall)
module vm './vm.bicep' = {
  name: 'vmDeployment'
  params: {
    location: 'East US'
    location2: 'East US 2'
    vmSize: 'Standard_B2ms'
    osDiskType: 'Standard_LRS'
    adminUsername: 'azureuser'
    adminPassword: 'Password123!'
    lbBackendPoolId: lbModule.outputs.backendPoolId
    webSubnetId: vnets.outputs.webSubnetId
    backendSubnetId: vnets.outputs.backendSubnetId
  }
  dependsOn: [
    vnets // Ensure the virtual networks are deployed before the VMs
    firewall // Ensure the firewall is deployed before the VMs
  ]
}

// Deploy the Load Balancer (depends on vnets)
module lbModule './lb.bicep' = {
  name: 'lbModule'
  params: {
    location: 'East US'
  }
  dependsOn: [
    vnets // Ensure the virtual networks are deployed before the load balancer
    firewall
  ]
}
