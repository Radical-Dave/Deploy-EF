#Set-StrictMode -Version Latest
#####################################################
# Deploy-EF
#####################################################
<#PSScriptInfo

.VERSION 0.1

.GUID f7b9bbb8-81f1-463e-8b44-f4e0c3febaac

.AUTHOR David Walker, Sitecore Dave, Radical Dave

.COMPANYNAME David Walker, Sitecore Dave, Radical Dave

.COPYRIGHT David Walker, Sitecore Dave, Radical Dave

.TAGS sitecore powershell local install iis solr

.LICENSEURI https://github.com/SitecoreDave/Deploy-EF/blob/main/LICENSE

.PROJECTURI https://github.com/SitecoreDave/Deploy-EF

.ICONURI

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
- see README.md

#>

<#
.SYNOPSIS
Deploy-EF!

.DESCRIPTION
PowerShell script that helps you Deploy-EF!

.EXAMPLE
PS> Deploy-EF 'projectPath' startupProjectPath

PS> Deploy-EF az armtemplate.json

.EXAMPLE
PS> Deploy-EF 'name' 'template'

.EXAMPLE
PS> Deploy-EF 'name' 'template' 'd:\repos'

.Link
https://github.com/Radical-Dave/Deploy-EF

.OUTPUTS
    System.String
#>
[CmdletBinding(SupportsShouldProcess=$true)]
Param(
	[Parameter(Mandatory=$true)]
	[string]$project="$(System.DefaultWorkingDirectory)/_vantage-core-api/Vantage.Common/Vantage.Common.csproj",
	[Parameter(Mandatory=$true)]
	[string]$startup_project="$(System.DefaultWorkingDirectory)/_vantage-core-api/Vantage.Core.API/Vantage.Core.API.csproj",
  [Parameter(Mandatory=$false)]
	[string]$connectionstring='',
  [Parameter(Mandatory=$false)]
	[string]$prefix='',
  [Parameter(Mandatory=$false)]
	[string]$env_name='',
  [Parameter(Mandatory=$false)]
	[string]$name=''
)
begin {
	$Global:ErrorActionPreference='Stop'
	$PSScriptName=($MyInvocation.MyCommand.Name.Replace(".ps1",""))
	$PSScriptVersion=(Test-ScriptFileInfo -Path $MyInvocation.MyCommand.Path | Select-Object -ExpandProperty Version)
	$PSCallingScript=if ($MyInvocation.PSCommandPath) { $MyInvocation.PSCommandPath | Split-Path -Parent } else { $null }
	Write-Verbose '#####################################################'
	Write-Host "# $PSScriptRoot/$PSScriptName $($PSScriptVersion):$project $startup_project $connectionstring $prefix $env_name called by:$PSCallingScript" -ForegroundColor White

  #if (!$prefix) { $prefix=$env:RELEASE_DEFINITIONNAME}
  #if (!$prefix) { $prefix="$(Release.DefinitionName)"}
  if (!$prefix) { $prefix="imagineperegrine"}

  #if (!$env_name) { $env_name=$env:RELEASE_ENVIRONMENTNAME}
  #if (!$env_name) { $env_name="$(Release.EnvironmentName)"}
  if (!$env_name) { $env_name="cd"}

  if (!$name -and $prefix -and $env_name) { $name = $prefix+'-'+$env_name}
  Write-Host "name:$name"

  #if (!$connectionstring) { $connectionstring=$env:${$key} } #:RELEASE_ENVIRONMENTNAME}
  if (!$connectionstring) {
    Write-Host 'connectionstring not passed.'
  } else {
    if ($connectionstring.StartsWith('key:')) {
      $vault = ""
      if ($connectionstring.Contains('/')) {
        $cssp =$connectionstring.Replace('key:','').Split('/')
        $vault = $cssp[0]
        $key = $cssp[1]
      } else {
        $key=$connectionstring.Replace('key:','')
      }
      $connectionstring = ""
      if (!$vault -and $prefix -and $env_name) { $vault = $prefix+'-'+$env_name}
      if (!$vault) {$vault='base-terraform-kv'}
      if (!$key) {
        $id=$name+'-dbs-connectionstring'
        $key=$id.Replace("-","_").ToUpper()
      }
      Write-Host "key:$key"
      if ($key) {
        if ($keyvault) { $keyvault=$env:TF_VAR_VAULT_NAME}
        #if ($keyvault) { $keyvault=$TF_VAR_VAULT_NAME}
        if (!$keyvault) {$keyvault=[System.Environment]::GetEnvironmentVariable('TF_VAR_VAULT_NAME','Machine')}
        if (!$keyvault) {$keyvault="base-terraform-kv"}
        Write-Host "keyvault:$keyvault"
        if ($keyvault) {
          #$connectionstring=(Get-AzKeyVaultSecret -VaultName $keyvault -Name $key -AsPlainText)+";Initial Catalog=$name-db;"
          #$secret=@(az keyvault secret show --name $name --vault-name $keyvault --output json)
          $secret = ""
          cmd /c "az keyvault secret show --name $id --vault-name $keyvault" '2>&1' | Tee-Object -Variable secret
          if ($secret) { 
            #Write-Host "secret:$secret"
            $connectionString = ($secret | ConvertFrom-Json).value
          }
          if ($connectionstring) {
            Write-Host "connectionString retrieved from $($keyvault):$connectionstring"
          }
        }
      }
    }
  }
}
process {
  if (!$connectionstring) {
    Write-Host "VaultSecret not found for $key"
  } else {
    if (!$connectionstring.Contains("Initial Catalog=")) {$connectionstring=$connectionstring+";Initial Catalog=$name-db;"}
    [System.Environment]::SetEnvironmentVariable('ConnectionStrings:VantageDatabase',$connectionstring)
    dotnet tool install -g dotnet-ef --version 6.0.1
    dotnet ef database update --project $project --startup-project $startup_project --connection $connectionstring --verbose
  }
}