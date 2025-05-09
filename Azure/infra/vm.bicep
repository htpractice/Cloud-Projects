// vm.bicep: Virtual Machines Configuration

param location string 
param location2 string
param vmSize string
param osDiskType string
param adminUsername string
param adminPassword string
param webSubnetId string // Subnet ID for the NICs (passed from vnets.bicep)
param backendSubnetId string // Subnet ID for the WS11 NIC (passed from vnets.bicep)

// Reference to Load Balancer Backend Pool ID (passed from lb.bicep)
param lbBackendPoolId string

// Availability Set for High Availability
resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-09-01' = {
  name: 'webServerAvailabilitySet'
  location: location
  sku: {
    name: 'Aligned' // Use aligned SKU for managed disks
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}

// Web Server 1 in East US
resource webServer1 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'webServer1'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySet.id
    }

    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    osProfile: {
      computerName: 'webserver1'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic1.id // Dynamically reference the NIC resource
        }
      ]
    }
  }
}

resource webServer2 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'webServer2'
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySet.id
    }

    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    osProfile: {
      computerName: 'webserver2'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic2.id // Dynamically reference the NIC resource
        }
      ]
    }
  }
}

// Custom Script Extension for webServer1
resource webServer1Extension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'installWebServer1'
  location: location // Use the location parameter directly
  parent: webServer1
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [] // No external files needed
      commandToExecute: 'bash -c "sudo apt update && sudo apt install -y nginx && echo Hello World from $(hostname) > /var/www/html/index.html && sudo systemctl restart nginx"'
    }
  }
}

// Custom Script Extension for webServer2
resource webServer2Extension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'installWebServer2'
  location: location2 // Use the location2 parameter directly
  parent: webServer2
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [] // No external files needed
      commandToExecute: 'bash -c "sudo apt update && sudo apt install -y nginx && echo Hello World from $(hostname) > /var/www/html/index.html && sudo systemctl restart nginx"'
    }
  }
}

resource ws11Vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'WS11'
  location: location2
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
    }
    osProfile: {
      computerName: 'WS11'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ws11Nic.id
        }
      ]
    }
  }
}

// Remote Desktop Gateway VM . This VM will be used to access the web servers
resource rdGatewayVm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: 'rdGateway'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS' // Change to an allowed value
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
    }
    osProfile: {
      computerName: 'rdGateway'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: rdGatewayNic.id
        }
      ]
    }
  }
}

/// NIC Configuration

// Attach Load Balancer Backend Pool to NICs
resource nic1 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'webServer1NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: webSubnetId // Use the parameter for the subnet ID
          }
          loadBalancerBackendAddressPools: [
            {
              id: lbBackendPoolId
            }
          ]
        }
      }
    ]
  }
}

resource nic2 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'webServer2NIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: webSubnetId // Use the parameter for the subnet ID
          }
          loadBalancerBackendAddressPools: [
            {
              id: lbBackendPoolId
            }
          ]
        }
      }
    ]
  }
}
// Remote Desktop Gateway NIC
resource rdGatewayNic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'rdGatewayNIC'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: webSubnetId
          }
        }
      }
    ]
  }
}

resource ws11Nic 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: 'ws11NIC'
  location: location2
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: backendSubnetId // Pass this from vnets.bicep
          }
        }
      }
    ]
  }
}


output vm1Id string = webServer1.id
output vm2Id string = webServer2.id
output ws11VmId string = ws11Vm.id
output rdGatewayVmId string = rdGatewayVm.id
output nic1Id string = nic1.id
output nic2Id string = nic2.id
output rdGatewayNicId string = rdGatewayNic.id
output ws11NicId string = ws11Nic.id

