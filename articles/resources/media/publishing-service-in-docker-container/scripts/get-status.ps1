<#
.Synopsis
    Get publishing service status.

.Example
  .\get-status.ps1

.Example
  .\get-status.ps1 -Uri 'http://localhost:5001/api/publishing/operations/status'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $Uri='http://localhost:5001/api/publishing/operations/status',
    [Parameter(Mandatory=$false)] $Port,
    [Parameter(Mandatory=$false)] $Output='c:\res\status.txt'
)
$url = $Uri
if ($Port){
  $url = "http://localhost:$Port/api/publishing/operations/status"
}
Invoke-WebRequest -Uri $url -OutFile $Output
Get-Content $Output