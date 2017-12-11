<#
.Synopsis
    Downloads and installs .net core windowshosting 1.1.0.

.Example
  .\install-dontnetcore-winhosting.ps1

.Example
  .\install-dontnetcore-winhosting.ps1 -Uri 'https://aka.ms/dotnetcore_windowshosting_1_1_0' -Resource 'c:\downloads'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $Uri='https://aka.ms/dotnetcore_windowshosting_1_1_0',
    [string] $Resource='c:\res\dotnetcore_windowshosting_1_1_0.exe'
)
try{
  if (!(Test-Path $Resource)) {
    Write-Host "Downloading donet core windows hosting..."
    Invoke-WebRequest -Uri $Uri -OutFile $Resource
  }
  Write-Host "Installing donet core windows hosting..."
  # THIS PROCESS MAY FAIL WITH ERROR
  # hcsshim::ImportLayer failed in Win32: The system cannot find the path specified. (0x3) layerId=\\?\C:\ProgramData\Docker\windowsfilter
  # RE-RUN docker build WHEN ENCOUNTER THIS ISSUE
  # Open issue: https://github.com/moby/moby/issues/32838
  # install dotnetcore_windowshosting
  #RUN powershell & $Resource /install /quiet
  # alternative way to install EXE
  Start-Process $Resource -ArgumentList '/install', '/quiet' -NoNewWindow -Wait
}
catch{
  Write-Error $_.ErrorDetails.Message
  Write-Error $_.InvocationInfo.PositionMessage
  Write-Host "If error message contains `'hcsshim::ImportLayer failed in Win32: The system cannot find the path specified. (0x3) layerId=\\?\C:\ProgramData\Docker\windowsfilter`', re-run `'docker build`' command. Refer to issue https://github.com/moby/moby/issues/32838 for more details."
  exit 1
}
