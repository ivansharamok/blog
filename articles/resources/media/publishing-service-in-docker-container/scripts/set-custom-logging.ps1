<#
.Synopsis
    Sets custom logging for publishing service.

.Example
  .\set-custom-logging.ps1

.Example
  .\set-custom-logging.ps1 -ServicePath 'c:\inetpub\wwwroot\sitecorepublishing' -Environment development
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $ServicePath='c:\inetpub\wwwroot\sitecorepublishing',
    [Parameter(Mandatory=$false)] $FileName='sc.custom.logging.json',
    [Parameter(Mandatory=$false)] $LogLevel='Debug',
    [Parameter(Mandatory=$false)] $Environment
)
if ($Environment){
  Write-Host "Setting logging level to `'$LogLevel`'"
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
    'Sitecore:Publishing:Logging:Filters:Sitecore' `
    '-v' $LogLevel '-f' $FileName '--environment' $Environment}
}
else {
  Write-Host "Setting logging level to `'$LogLevel`'"
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Logging:Filters:Sitecore' `
  '-v' $LogLevel '-f' $FileName}
}