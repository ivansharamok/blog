<#
.Synopsis
    Unpackss publishing service from a package.

.Example
  .\unpack-pubservice.ps1

.Example
  .\unpack-pubservice.ps1 -PackagePath 'c:\res\Sitecore Publishing Service 2.1.0 rev. 171009.zip' -DestPath 'c:\inetpub\wwwroot\sitecorepublishing'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $PackagePath='c:\res\Sitecore Publishing Service 2.1.0 rev. 171009.zip',
    [string] $DestPath='c:\inetpub\wwwroot\sitecorepublishing'
)
if (!(Test-Path $DestPath)) { New-Item -Path $DestPath -ItemType Directory }
Write-Host "Unpacking publishing service..."
# expand pub service zip
Expand-Archive -LiteralPath $PackagePath -DestinationPath $DestPath
# reset ACL permissions in case they are corrupted after unzip
$acl = Get-Acl $DestPath
Set-Acl $DestPath $acl
