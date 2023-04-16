#Login-AzureRmAccount
#$PSVersionTable.PSVersion
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "lr-digitalplatform-sandpit-rg",
    # The name of arm template file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile = "azuredeploy.json",
    # The name of deployment
    [Parameter(Mandatory = $false)]
    [string]$deploymentname = "storage_witncontainer_deployment",
    # The name of storage account type
    [Parameter(Mandatory = $false)]
    [string]$storageaccounttype = "Standard_RAGRS",
    # The name of storage account type
    [Parameter(Mandatory = $false)]
    [string]$storagekind = "StorageV2",
    # The name of storage account name
    [Parameter(Mandatory = $false)]
    [string]$storageaccountname = "lrdigitalplatformstorage",
    # The name of storage account  access tier
    [Parameter(Mandatory = $false)]
    [string]$accessTier = "Hot",
    # The name of container with space seprated
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateContainers = "customer1filestorage customer2filestorage customer3filestorage customer4filestorage customer5filestorage",
    # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ', '_'), '3.0.0')
}
catch { }

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version 3

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}
$lrTemplatefile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile))

$ParametersObj = @{
    storagekind        = $storagekind
    storageaccounttype = $storageaccounttype
    storageaccountname = $storageaccountname
    accessTier         = $accessTier
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile `
            -TemplateParameterObject $ParametersObj )
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    #Start the 1st deployment to create sql server and database instances
    New-AzResourceGroupDeployment -Name ($deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile `
        -TemplateParameterObject $ParametersObj  `
        -Force -Verbose


   

    <# $storageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
        -Name $ParametersObj.storageaccountname

    # Retrieve the context.
    $ctx = $storageAccount.Context
    $StartTime = Get-Date
    $expiryTime = (get-date).AddYears(1)
    $permission = "rwl"
    $lrTemplateContainers.split() |New-AzureStorageContainerStoredAccessPolicy -Context $ctx  -Policy "storageaccesspolicy" -ExpiryTime $expiryTime -Permission $permission
    $allcontainers = $lrTemplateContainers.split() | New-AzureStorageContainer -Permission Off -Context $ctx
    #$allcontainers= $lrTemplateContainers.split() | Get-AzureStorageContainer  -Context $ctx
    ForEach ($cont In $allcontainers) {
        $sasToken = New-AzureStorageContainerSASToken -Name $cont.Name -Permission rwdl -Context $ctx -StartTime $StartTime -ExpiryTime $expiryTime
        Write-Host $sasToken.ToString().Insert(0, $cont.CloudBlobContainer.Uri.AbsoluteUri)
    }
#>
}


#Remove-AzureRmAlertRule -ResourceGroup "Default-Web-CentralUS" -Name "myalert-7da64548-214d-42ca-b12b-b245bb8f0ac8"
#Remove-AzureRmAutoscaleSetting  -ResourceGroup "lr-digitalplatform-sandpit-rg" -Name "lr-schemes-serviceplan-nonprod-lr-digitalplatform-sandpit-rg"






