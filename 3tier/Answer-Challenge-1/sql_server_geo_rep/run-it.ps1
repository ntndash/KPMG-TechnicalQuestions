#Login-AzureRmAccount
#$PSVersionTable.PSVersion

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "cocacola-prod-rg",
    # The name of arm template file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_sqlserver_gep_rep = "..\arm_templates\sql_server_geo_rep_nonenv\azuredeploy.json",
    # The name of deployment
    [Parameter(Mandatory = $false)]
    [string]$deploymentname = "Sql_server_geo_rep_deployment",
    # The name of arm template parameter file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile = "azuredeploy.parameters.json",
     # The list of db for enabling failover
     #[Parameter(Mandatory = $false)]
     #[string]$dbname = "lr-digitalplatform-db-dev lr-digitalplatform-db-qa",
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


$lrTemplateparameterfile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile))
$lrTemplatefile_sqlserver_gep_rep = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_sqlserver_gep_rep))
function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_sqlserver_gep_rep `
            -TemplateParameterFile $lrTemplateparameterfile)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {

    Write-Output 'Start the 1st deployment to create sql server and database failover group instances'
    #Start the 1st deployment to create sql server and database failover group instances
    New-AzResourceGroupDeployment -Name ($deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_sqlserver_gep_rep `
        -TemplateParameterFile $lrTemplateparameterfile `
        -Force -Verbose
       }
