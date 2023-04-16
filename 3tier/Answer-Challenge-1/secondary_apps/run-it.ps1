#Login-AzureRmAccount
#$PSVersionTable.PSVersion`
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "cocacola-prod-rg",
    # The name of app  deployment name
    [Parameter(Mandatory = $false)]
    [string]$webdeploymentname = "mb-prod-secondary-deployment",
    # The name of TM deployment name
    [Parameter(Mandatory = $false)]
    [string]$app_rules_deploymentname = "prod-TM-deployment",
    # The name of file for web/api apps arm template
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_webapps = "..\arm_templates\webapps_noslots_loc\azuredeploy.json",
    # The name of file for web/api apps arm template parameter
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_webapps = "azuredeploy.parameters.json",
    # The name of traffic manager ARM template file  deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_traffic = "..\arm_templates\trafficmanager\azuredeploy.json",
    # The name of traffic manager ARM template parameter file  deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_traffic = "..\trafficmanager\azuredeploy.parameters.json",
    # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

$lrTemplatefile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_webapps))
$lrTemplateparameterfile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_webapps))
$lrTemplatefile_traffic = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_traffic))
$lrTemplateparameterfile_traffic = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_traffic))

try {
    [Microsoft.Azure.Common.Authentication.AzureSession]::ClientFactory.AddUserAgent("VSAzureTools-$UI$($host.name)".replace(' ', '_'), '3.0.0')
}
catch { }
$ErrorActionPreference = 'Stop'
$ErrorMessages = ''
Set-StrictMode -Version 3
function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}


if ($ValidateOnly) {
    $ErrorMessages += Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_webapps `
            -TemplateParameterFile $lrTemplateparameterfile_webapps)
    $ErrorMessages += Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_traffic `
            -TemplateParameterFile $lrTemplateparameterfile_traffic)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {
    Write-Output 'Start the deployment to create webapps server and no slots with no app insights'
    New-AzResourceGroupDeployment -Name ($webdeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_webapps `
        -TemplateParameterFile $lrTemplateparameterfile_webapps `
        -Force -Verbose
        Write-Output 'Start the Traffic Manager deployment for [web/api]-apps & Secondary server'
    New-AzResourceGroupDeployment -Name ($app_rules_deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_traffic `
        -TemplateParameterFile $lrTemplateparameterfile_traffic `
        -Force -Verbose
}