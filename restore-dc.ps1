$vmName = "addr-dc-001"
$restoreRgName = "addr-rg-isolated-001"
$resourceGroupName = "addr-rg"
$restoreStorageAccountName = "pocdhladdrrestores"

# Select vault
$targetVault = Get-AzRecoveryServicesVault -ResourceGroupName $resourceGroupName -Name "addr-rsv"
$targetVault.ID

# check existing Azure VM backups
Get-AzRecoveryServicesBackupContainer -VaultId $targetVault.ID -ContainerType "AzureVM"

# Manually trigger backup job
#$namedContainer = Get-AzRecoveryServicesBackupContainer -ContainerType "AzureVM" -FriendlyName $vmName -VaultId $targetVault.ID
#$item = Get-AzRecoveryServicesBackupItem -Container $namedContainer -WorkloadType "AzureVM" -VaultId $targetVault.ID
#$endDate = (Get-Date).AddDays(6).ToUniversalTime()
#$job = Backup-AzRecoveryServicesBackupItem -Item $item -VaultId $targetVault.ID -ExpiryDateTimeUTC $endDate

#region Restore backup
$namedContainer = Get-AzRecoveryServicesBackupContainer  -ContainerType "AzureVM" -FriendlyName $vmName -VaultId $targetVault.ID
$backupItem = Get-AzRecoveryServicesBackupItem -Container $namedContainer  -WorkloadType "AzureVM" -VaultId $targetVault.ID

# choose recovery point
$startDate = (Get-Date).AddDays(-7)
$endDate = Get-Date
$rp = Get-AzRecoveryServicesBackupRecoveryPoint -VaultId $targetVault.ID -Item $backupitem -StartDate $startdate.ToUniversalTime() -EndDate $enddate.ToUniversalTime()
$rp[0]

Set-AzRecoveryServicesVaultContext -Vault $targetVault
$restorejob = Restore-AzRecoveryServicesBackupItem -RecoveryPoint $rp[0] -StorageAccountName $restoreStorageAccountName -StorageAccountResourceGroupName $restoreRgName -VaultId $targetVault.ID  -TargetResourceGroupName $restoreRgName 
$restorejob

Wait-AzRecoveryServicesBackupJob -Job $restorejob -Timeout 43200

# get detailed results
$restorejob = Get-AzRecoveryServicesBackupJob -Job $restorejob -VaultId $targetVault.ID

if ($restorejob.Status -ne "Completed") {
    $details = Get-AzRecoveryServicesBackupJobDetail -Job $restorejob -VaultId $targetVault.ID
    $details.ErrorDetails

    throw "Restore operation hasn't completed -> stopping."
}

$details = Get-AzRecoveryServicesBackupJobDetail -Job $restorejob -VaultId $targetVault.ID

# deploy VM
$properties = $details.properties
$storageAccountName = $properties["Target Storage Account Name"]
$containerName = $properties["Config Blob Container Name"]
$templateBlobURI = $properties["Template Blob Uri"]

$parts = $templateBlobURI.Split("/")

Set-AzCurrentStorageAccount -Name $storageAccountName -ResourceGroupName $resourceGroupName
$templateBlobFullURI = New-AzStorageBlobSASToken -Container $containerName -Blob $parts[4] -Permission r -FullUri

$deployment = New-AzResourceGroupDeployment -Name "DeployRestoredVM" -ResourceGroupName $restoreRgName -TemplateUri $templateBlobFullURI -TemplateParameterObject @{
    VirtualMachineName          = "$($vmName)-isolated-001"
    VirtualNetwork              = "addr-vnet-isolated-001"
    VirtualNetworkResourceGroup = $restoreRgName
}

if ($deployment.ProvisioningState -ne "Succeeded") {
    throw "Deployment of restored VM failed"
    $deployment
}
#endregion
