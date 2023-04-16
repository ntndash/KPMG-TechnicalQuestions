[CmdletBinding(SupportsShouldProcess = $true)]
param(
    # The name of resource group
    [Parameter(Mandatory = $false)]
    [string]$resourcegroup = "cocacola-prod-rg",
    # The name of arm template file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplatefile =  "..\..\arm_templates\webtest\azuredeploy.json",
    # The name of deployment
    [Parameter(Mandatory = $false)]
    [string]$deploymentname = "webtest_deployment",
    # The name of arm template parameter file
    [Parameter(Mandatory = $false)]
    [string]$lrTemplateparameterfile = "azuredeploy.parameters.json",

     # The true/false value for validate the templates
    [Parameter(Mandatory = $false)]
    [switch] $ValidateOnly
)

$lrTemplatefile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplatefile))
$lrTemplateparameterfile = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, $lrTemplateparameterfile))



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


    Write-Output 'Start the deployment to create webtest for apps'
    New-AzResourceGroupDeployment -Name ($deploymentname + '-' + ((Get-Date).ToUniversalTime()).ToString('MMdd-HHmm')) `
        -ResourceGroupName $resourcegroup `
        -TemplateFile $lrTemplatefile `
        -TemplateParameterFile $lrTemplateparameterfile `
        -Force -Verbose

}
