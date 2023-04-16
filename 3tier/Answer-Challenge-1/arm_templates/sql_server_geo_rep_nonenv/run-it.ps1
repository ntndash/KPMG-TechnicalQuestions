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
    [string]$deploymentname = "Sql_server_deployment",
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

function Format-ValidationOutput {
    param ($ValidationOutput, [int] $Depth = 0)
    Set-StrictMode -Off
    return @($ValidationOutput | Where-Object { $_ -ne $null } | ForEach-Object { @('  ' * $Depth + ': ' + $_.Message) + @(Format-ValidationOutput @($_.Details) ($Depth + 1)) })
}

if ($ValidateOnly) {
    $ErrorMessages = Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile `
            -TemplateParameterFile $lrTemplateparameterfile)
    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {

#$dbnamearraywithresource = ""
#ForEach ($db in $dbname.Split())
#{
# $dbnamearraywithresource+=(Get-AzureRmResource -ResourceGroupName lr-digitalplatform-sandpit-rg -Name  lr-digitalplatform-sqlserver-nonprod/$db).ResourceId +','
#}
#$dbnamearraywithresource
    #Start the 1st deployment to create sql server and database instances
    New-AzResourceGroupDeployment -Name ($deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile `
        -TemplateParameterFile $lrTemplateparameterfile `
        -Force -Verbose
       }


#Remove-AzureRmAlertRule -ResourceGroup "Default-Web-CentralUS" -Name "myalert-7da64548-214d-42ca-b12b-b245bb8f0ac8"
#Remove-AzureRmAutoscaleSetting  -ResourceGroup "lr-digitalplatform-sandpit-rg" -Name "lr-schemes-serviceplan-nonprod-lr-digitalplatform-sandpit-rg"

#[resourceId('Microsoft.SQL/servers/databases', 'serverName', 'databaseName')]