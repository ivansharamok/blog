<#
.Synopsis
    Starts publishing service as foreground process.

.Example
  .\start-service.ps1

.Example
  .\start-service.ps1 -URLs 'http://0.0.0.0:5001;http://localhost:80' 

.Example
  .\start-service.ps1 -URLs 'http://0.0.0.0:5001;http://localhost:80' -Environment development
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $ServicePath='c:\inetpub\wwwroot\sitecorepublishing',
    [Parameter(Mandatory=$false)] $URLs='http://0.0.0.0:5001',
    [Parameter(Mandatory=$false)] $Environment
)
Write-Host "Staring publishing service to respond to $URLs"
# start publishing service
if ($Environment){
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" '--urls' $URLs '--environment' $Environment}  
}
else {
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" '--urls' $URLs}  
}
# run http://<hostip>:5001/api/publishing/operations/status to get status of the service. Response {status: 0} means everything is OK.