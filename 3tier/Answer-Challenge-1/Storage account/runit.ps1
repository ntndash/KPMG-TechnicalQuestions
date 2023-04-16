#Login-AzureRmAccount
#$PSVersionTable.PSVersion
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "lrsb-safetyscanner-glencore-prod-rg",
    # The name of arm template file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile = "..\..\arm_templates\storage_a_c\azuredeploy.json",
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
    [string]$storageaccountname = "lrsbsafetysgleprod",
    # The name of storage account  access tier
    [Parameter(Mandatory = $false)]
    [string]$accessTier = "Hot",
   
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
   
}