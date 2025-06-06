// storage.bicep
// Deploys storage accounts with static website hosting enabled
param location1 string = 'East US'
param location2 string = 'East US 2'

resource primaryStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastuszrsstatic${uniqueString(resourceGroup().id)}'
  location: location1
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Hot'
  }
}

// Enable static website hosting
resource staticWebsite 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = {
  name: '${primaryStorage.name}/default/$web'
  properties: {
    publicAccess: 'Blob'
  }
}

// Secondary storage for backup/redundancy
resource backupStorage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastus2grsbackup${uniqueString(resourceGroup().id)}'
  location: location2
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    accessTier: 'Cool' // Backup storage can use cool tier for cost savings
  }
}

output primaryStorageId string = primaryStorage.id
output primaryStorageName string = primaryStorage.name
output staticWebsiteUrl string = primaryStorage.properties.primaryEndpoints.web
output backupStorageId string = backupStorage.id
output backupStorageName string = backupStorage.name
