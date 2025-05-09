param location1 string
param location2 string

// Zone-Redundant Storage Account in EastUS (Updated to Standard_LRS)
resource eastUSStorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastus${uniqueString(resourceGroup().id)}' // Shortened prefix to ensure valid name
  location: location1
  sku: {
    name: 'Standard_LRS' // Updated to comply with policy
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// Geo-Redundant Storage Account in EastUS2
resource eastUS2StorageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: 'eastus2${uniqueString(resourceGroup().id)}' // Shortened prefix to ensure valid name
  location: location2
  sku: {
    name: 'Standard_GRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
  }
}

// File Services for EastUS2 Storage Account
resource eastUS2FileServices 'Microsoft.Storage/storageAccounts/fileServices@2023-01-01' = {
  name: 'default'
  parent: eastUS2StorageAccount
}

// Azure File Share for EastUS2 Storage Account
resource eastUS2FileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-01-01' = {
  name: 'ws11fileshare'
  parent: eastUS2FileServices
  properties: {
    shareQuota: 100 // Quota in GB
  }
}

// Outputs for EastUS Storage
output eastUSStorageAccountName string = eastUSStorageAccount.name
output eastUSBlobServiceUrl string = 'https://${eastUSStorageAccount.name}.blob.${environment().suffixes.storage}'

// Outputs for EastUS2 Storage
output eastUS2StorageAccountName string = eastUS2StorageAccount.name
output eastUS2BlobServiceUrl string = 'https://${eastUS2StorageAccount.name}.blob.${environment().suffixes.storage}'

// Output File Share URL
output eastUS2FileShareUrl string = 'https://${eastUS2StorageAccount.name}.file.${environment().suffixes.storage}/ws11fileshare'
