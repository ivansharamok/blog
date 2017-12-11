<#
.Synopsis
    Installs IIS web site for publishing service. When running publishing service via IIS web site, you must install Windows features Web-Server and Web-Asp-Net45.

.Example
  .\install-iiswebsite.ps1

.Example
  .\install-iiswebsite.ps1 -SiteName 'publishing.service' -Port 5001 
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $ServicePath='c:\inetpub\wwwroot\sitecorepublishing',
    [Parameter(Mandatory=$false)] $SiteName='publishing.service',
    [Parameter(Mandatory=$false)] $Port=5001
    # [Parameter(Mandatory=$false)] $Environment
)
# install .NET Framework - this doesn't seem to be needed.
#RUN powershell Add-WindowsFeature NET-Framework-45-ASPNET
#RUN powershell Add-WindowsFeature NET-Framework-45-Core
Write-Host "Installing Web-Server features that contains IIS service..."
# install IIS
Add-WindowsFeature Web-Server
Write-Host "Adding Web-Asp-Net45 feature..."
# publishing service has dependency on full .NET Framework for now when it's run via IIS web site
# the feature must be installed after manipulations with iis sites
Add-WindowsFeature Web-Asp-Net45
Write-Host "Installing publishing service IIS web site..."
# install pub service into iis
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'iis' 'install' '--sitename' $SiteName '--apppool' $SiteName '--port' $Port '--force'}
# run http://<hostname>:5001/api/publishing/operations/status to get status of the service. Response {status: 0} means everything is OK.
# import WebAdministration module to work with IIS objects, remove default web site and add binding for publishing.service web site
#RUN powershell Import-Module WebAdministration; \
#    Remove-Website -Name 'default web site'; \
#    New-WebBinding -Name 'publishing.service' -Protocol 'http' -Port 5001 -IPAddress '*'

# delete default iis web site
#Write-Host "Removing IIS default web site..."
#cmd /S /C "C:\Windows\System32\inetsrv\appcmd.exe delete site `"default web site`""
Write-Host "Setting default binding for publishing service site..."
# set iis site binding using appcmd.exe
$binding='*:' + $Port + ':'
cmd /S /C "C:\Windows\System32\inetsrv\appcmd.exe set site /site.name:$SiteName /+bindings.[protocol='http',bindingInformation=`'$binding`']"
# must run dotnetcore installation after web-asp-net45 feature installed
# if dotnetcore was already installed, run it with /repair key
Start-Process 'C:\res\dotnetcore_windowshosting_1_1_0.exe' -ArgumentList '/repair', '/quiet' -NoNewWindow -Wait