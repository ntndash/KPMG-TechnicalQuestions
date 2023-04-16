#Login-AzureRmAccount
#$PSVersionTable.PSVersion
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "cocacola-prod-rg",
    # The name of web/api apps deployment name
    [Parameter(Mandatory = $false)]
    [string]$appdeploymentname = "mb-prod-deployment",
    # The name of file for web/api apps arm template
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_webapps = "arm_templates\webapps\azuredeploy.json",
    # The name of file for web/api apps arm template parameter
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_webapps = "webapps\azuredeploy.parameters.json",
   
    # The name of web/api app appinsight alert  deployment
    [Parameter(Mandatory = $false)]
    [string]$app_rules_deploymentname = "app_rules_deployment",
      # The name of file for sql server arm template
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_sqlserver = "arm_templates\SQL_Server_audit\azuredeploy.json",
    # The name of file for sql server arm template parameter
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_sqlserver = "sql_server\azuredeploy.parameters.json",
   # The name of web/api app appinsight alert & Webtest ARM template file  deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_webtest = "arm_templates\webtest\azuredeploy.json",
    # The name of web/api app appinsight alert & web Test ARM template parameter file  deployment
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_webtest = "webtest\azuredeploy.parameters.json",
    # The name of notification hub  deployment
    [Parameter(Mandatory = $false)]
    [string]$appinsight_deploymentname = "appinsight_deployment",
    # The name of file for AppInsights arm template
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile_appinsight = "arm_templates\appinsightrules_oneappinsight_advance\azuredeploy.json",
    # The name of file for web/api apps arm template parameter
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile_appinsight = "appinsightrules_oneappinsight\azuredeploy.parameters.json",
    # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

$lrTemplatefile_sqlserver = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_sqlserver))
$lrTemplateparameterfile_sqlserver = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_sqlserver))
$lrTemplatefile_webtest = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_webtest))
$lrTemplateparameterfile_webtest = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_webtest))
$lrTemplatefile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_webapps))
$lrTemplateparameterfile_webapps = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_webapps))
$lrTemplatefile_appinsight = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile_appinsight))
$lrTemplateparameterfile_appinsight = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile_appinsight))



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
            -TemplateFile $lrTemplatefile_appinsight `
            -TemplateParameterFile $lrTemplateparameterfile_appinsight)

$ErrorMessages += Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_sqlserver `
            -TemplateParameterFile $lrTemplateparameterfile_sqlserver)

    $ErrorMessages += Format-ValidationOutput (Test-AzResourceGroupDeployment -ResourceGroupName $resourcegroup `
            -TemplateFile $lrTemplatefile_webtest `
            -TemplateParameterFile $lrTemplateparameterfile_webtest)



    if ($ErrorMessages) {
        Write-Output '', 'Validation returned the following errors:', @($ErrorMessages), '', 'Template is invalid.'
    }
    else {
        Write-Output '', 'Template is valid.'
    }
}
else {


    Write-Output 'Start the deployment to create webapps/Apiapps/MobileApps server and slots with app insights'
    New-AzResourceGroupDeployment -Name ($appdeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_webapps `
        -TemplateParameterFile $lrTemplateparameterfile_webapps `
        -Force -Verbose `

    Write-Output 'Start the deployment to create app insights'
    New-AzResourceGroupDeployment -Name ($appinsight_deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_appinsight `
        -TemplateParameterFile $lrTemplateparameterfile_appinsight `
        -Force -Verbose

Write-Output 'Start the deployment to create sql server and database instances'
    New-AzResourceGroupDeployment -Name ($appdeploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_sqlserver `
        -TemplateParameterFile $lrTemplateparameterfile_sqlserver `
        -Force -Verbose
        
    Write-Output 'Start the appinsight rules and testcase rules for webtest deployment for [web/api]-apps server'
    New-AzResourceGroupDeployment -Name ($app_rules_deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile_webtest `
        -TemplateParameterFile $lrTemplateparameterfile_webtest `
        -Force -Verbose

}