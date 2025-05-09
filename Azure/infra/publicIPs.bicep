param location1 string
param location2 string

// Public IP for EastUS VPN Gateway
resource eastUSPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'eastUSVpnGatewayPublicIP'
  location: location1
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

// Public IP for EastUS2 VPN Gateway
resource eastUS2PublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'eastUS2VpnGatewayPublicIP'
  location: location2
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

// Public IP for Azure Firewall
resource firewallPublicIP 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: 'eastUS2Firewall-publicIP'
  location: location2
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Output the public IP addresses
output eastUSPublicIPId string = eastUSPublicIP.id
output eastUS2PublicIPId string = eastUS2PublicIP.id
output firewallPublicIPId string = firewallPublicIP.id
output eastUSPublicIPName string = eastUSPublicIP.name
output eastUS2PublicIPName string = eastUS2PublicIP.name
output firewallPublicIPName string = firewallPublicIP.name
