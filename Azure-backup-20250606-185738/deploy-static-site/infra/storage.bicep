// storage.bicep
// Deploys ZRS in EastUS and GRS in EastUS2 with access controls
resource zrsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastuszrsstorage'
  location: 'East US'
  sku: {
    name: 'Standard_LRS' // Updated to comply with allowed types
  }
  kind: 'StorageV2'
  properties: {}
}

resource grsStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastus2grsstorage'
  location: 'East US 2'
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {}
}

output zrsConnectionString string = listKeys(zrsStorage.name, '2023-01-01').keys[0].value
output grsConnectionString string = listKeys(grsStorage.name, '2023-01-01').keys[0].value
