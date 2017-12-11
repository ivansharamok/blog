<#
.Synopsis
    Package Sitecore instance for cloud deployment. Script uses Sitecore Azure SDK.

.Example
  .\packageSoA.ps1 -EnvironmentType xM1 -SitecoreZipPath 'D:\simRepo\Sitecore 8.2 rev. 161115.zip' 
        -DestinationFolderPath .\xM1 
        
.Example
  .\packageSoA.ps1 -SitecoreZipPath 'D:\simRepo\Sitecore 8.2 rev. 161115.zip' 
        -DestinationFolderPath .\xP0 -CargoPayloadFolderPath .\resources\8.2.1\cargopayloads -ArchiveAndParameterXmlPath .\resources\8.2.1\msdeployxmls 
        -CommonConfigPath .\resources\8.2.1\configs\common.packaging.config.json -SkuConfigPath .\resources\8.2.1\configs\xp0.packaging.config.json
.Example
  .\packageSoA.ps1 -EnvironmentType aM0 -SitecoreZipPath 'D:\simRepo\Sitecore 8.2 rev. 161115_nodb.zip' 
        -DestinationFolderPath .\aM0 -CargoPayloadFolderPath .\resources\8.2.1\cargopayloads -ArchiveAndParameterXmlPath .\resources\8.2.1\msdeployxmls 
        -CommonConfigPath '.\resources\8.2.1\configs\common.app.packaging.config.json' -SkuConfigPath .\resources\8.2.1\configs\aM0.packaging.config.json
.Example
  .\packageSoA.ps1 -EnvironmentType aM0 -SitecoreZipPath 'D:\simRepo\Sitecore 8.2 rev. 161115.zip' 
        -DestinationFolderPath .\aM0 -CargoPayloadFolderPath .\resources\8.2.1\cargopayloads -ArchiveAndParameterXmlPath .\resources\8.2.1\msdeployxmls 
        -CommonConfigPath '.\resources\8.2.1\configs\common.app.packaging.config.json' -SkuConfigPath .\resources\8.2.1\configs\aM0.packaging.config.json
        -AppSkuConfigPath '.\resources\8.2.1\configs\xm.app.packaging.config.json' -appSitecoreZipPath 'D:\simRepo\Sitecore 8.2 rev. 161115_nodb.zip' -IncludeAppOnly
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $EnvironmentType='xM1',
    [Parameter(Mandatory=$true)] $SitecoreZipPath,
    [Parameter(Mandatory=$true)] $DestinationFolderPath,
    [Parameter(Mandatory=$false)] $CargoPayloadFolderPath='.\resources\8.2.1\cargopayloads',
    [Parameter(Mandatory=$false)] $ArchiveAndParameterXmlPath='.\resources\8.2.1\msdeployxmls',
    [Parameter(Mandatory=$false)] $CommonConfigPath='.\resources\8.2.1\configs\common.packaging.config.json',
    [Parameter(Mandatory=$false)] $SkuConfigPath='.\resources\8.2.1\configs\$EnvironmentType.packaging.config.json',
    [Parameter(Mandatory=$false)] $AppCommonConfigPath='.\resources\8.2.1\configs\common.app.packaging.config.json',
    [Parameter(Mandatory=$false)] $AppSkuConfigPath='.\resources\8.2.1\configs\xm.app.packaging.config.json',
    [Parameter(Mandatory=$false)] $appSitecoreZipPath,
    [switch] $IncludeAppOnly
)

# Clear any existing errors
#$Error.Clear();
# Display error if it occurs
<#
Trap
{
    Write-Host "Error: $($_.Exception.GetType().FullName)" -ForegroundColor Red ; 
    Write-Host $_.Exception.Message; 
    Write-Host $_.Exception.StackTrack;

    # alternative way to output detailed error info
    # $ErrorRecord=$Error[0]
    # $ErrorRecord | Format-List * -Force
    # $ErrorRecord.InvocationInfo |Format-List *
    # $Exception = $ErrorRecord.Exception
    # for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
    # {   "$i" * 80
        # $Exception |Format-List * -Force
    # }
    break;
}
#>

function Set-FullPath([string]$path){
  if($path.StartsWith(".")){
    $fullPath = $PSScriptRoot + $path.Substring(1)
  }
  else {
    $fullPath = $path
  }
  return $fullPath
}

# SDK path
$SCSDK=".\tools"
# script root
$ScriptRoot = $PSScriptRoot

# If destination folder starts with '.', convert the relative path into absolute. Otherwise, %systemroot% could be used.
$DestinationFolderPath = Set-FullPath $DestinationFolderPath
$SitecoreZipPath = Set-FullPath $SitecoreZipPath
$CargoPayloadFolderPath = Set-FullPath $CargoPayloadFolderPath
$ArchiveAndParameterXmlPath = Set-FullPath $ArchiveAndParameterXmlPath
$CommonConfigPath = Set-FullPath $CommonConfigPath
$SkuConfigPath = Set-FullPath $SkuConfigPath

# Import Sitecore.Cloud.Cmdlets PS module. This script expects the module to be located in /tools folder in relative location to the script.
Import-Module $SCSDK\Sitecore.Cloud.Cmdlets.psm1
# Verify that import was successful
$importedModule = Get-Module Sitecore.Cloud.Cmdlets
if ($importedModule -eq $null){
  Write-Output "Cannot proceed with script execution as Sitecore.Cloud.Cmdlets module could not be loaded. Script terminated." -ErrorAction Stop
  exit
}

try{
    # if IncludeAppOnly supplied, then make sure all necessary parameters are provided. Otherwise, stop the process.
    if ($IncludeAppOnly){
      if (!($AppCommonConfigPath) -or !($AppSkuConfigPath) -or !($appSitecoreZipPath)){
        Write-Error "Parameters AppCommonConfigPath, AppSkuConfigPath and appSitecoreZipPath must be supplied when IncludeAppOnly is provided"
        exit
      }
      Write-Debug "Creating slot (app only) package"
      Start-SitecoreAzurePackaging -sitecorePath $appSitecoreZipPath -destinationFolderPath $DestinationFolderPath -cargoPayloadFolderPath $CargoPayloadFolderPath -archiveAndParameterXmlPath $ArchiveAndParameterXmlPath -commonConfigPath $AppCommonConfigPath -skuConfigPath $AppSkuConfigPath
      #Write-Debug "Slot package created successfully!"
    }
    # expand arguments in case they have variables in them
    $SkuConfigPath = $ExecutionContext.InvokeCommand.ExpandString($SkuConfigPath)
    Write-Debug "Parameters: `r`n$EnvironmentType `r`n$SitecoreZipPath `r`n$CargoPayloadFolderPath `r`n$ArchiveAndParameterXmlPath `r`n$CommonConfigPath `r`n$SkuConfigPath"
    Write-Debug "Current location: $PSScriptRoot"
    Write-Debug "Get-Location: $(Get-Location)"
#    Write-Host "First line inside Try block"
    Start-SitecoreAzurePackaging -sitecorePath $SitecoreZipPath -destinationFolderPath $DestinationFolderPath -cargoPayloadFolderPath $CargoPayloadFolderPath -archiveAndParameterXmlPath $ArchiveAndParameterXmlPath -commonConfigPath $CommonConfigPath -skuConfigPath $SkuConfigPath
    #Write-Debug "Package created successfully!"
}
catch{
    Write-Error $_.Exception.Message
    Write-Error $_.Exception.StackTrace
}