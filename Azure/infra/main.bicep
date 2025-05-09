module publicIPs './publicIPs.bicep' = {
  name: 'publicIPsDeployment'
  params: {
    location1: 'East US'
    location2: 'East US 2'
  }
}

module vnets './vnets.bicep' = {
  name: 'vnetsDeployment'
  params: {
    location1: 'East US'
    location2: 'East US 2'
    vnetPrefix1: '10.0.0.0/16'
    vnetPrefix2: '10.1.0.0/16'
    webSubnetPrefix: '10.0.1.0/24'
    backendSubnetPrefix: '10.1.1.0/24'
    GatewaySubnet1Prefix: '10.0.2.0/27'
    GatewaySubnet2Prefix: '10.1.20.0/27'
    AzureFirewallSubnetPrefix: '10.1.2.0/24'
    vnetName1: 'eastUSVNet'
    vnetName2: 'eastUS2VNet'
    natGatewayPublicIPId: publicIPs.outputs.natGatewayPublicIPId
  }
}

module lb './lb.bicep' = {
  name: 'lbDeployment'
  params: {
    location: 'East US'
    lbName: 'webServerLoadBalancer'
  }
}

// Don't have the permission to create the gateways in the current subscription
//module gateways './gateways.bicep' = {
//  name: 'gatewaysDeployment'
//  params: {
//    location1: 'East US'
//    location2: 'East US 2'
//    eastUSVNetId: vnets.outputs.eastUSVNetId
//    eastUS2VNetId: vnets.outputs.eastUS2VNetId
//    eastUSPublicIPId: publicIPs.outputs.eastUSPublicIPId
//    eastUS2PublicIPId: publicIPs.outputs.eastUS2PublicIPId
//  }
//}

module firewall './firewall.bicep' = {
  name: 'firewallDeployment'
  params: {
    location: 'East US 2'
    vnetId: vnets.outputs.eastUS2VNetId
    firewallPublicIPId: publicIPs.outputs.firewallPublicIPId
  }
}

module nsgs './nsgs.bicep' = {
  name: 'nsgsDeployment'
  params: {
    location1: 'East US'
    location2: 'East US 2'
  }
}

module storage './storage.bicep' = {
  name: 'storageDeployment'
  params: {
    location1: 'East US'
    location2: 'East US 2'
  }
}

module vms './vm.bicep' = {
  name: 'vmsDeployment'
  params: {
    location: 'East US'
    location2: 'East US 2'
    vmSize: 'Standard_B2ms'
    osDiskType: 'Standard_LRS'
    adminUsername: 'azureuser'
    adminPassword: 'P@ssw0rd123!' // Replace with a secure password or use a parameter
    webSubnetId: vnets.outputs.webSubnetId
    backendSubnetId: vnets.outputs.backendSubnetId
    lbBackendPoolId: lb.outputs.backendPoolId // Use the backend pool ID from the Load Balancer module
  }
}
