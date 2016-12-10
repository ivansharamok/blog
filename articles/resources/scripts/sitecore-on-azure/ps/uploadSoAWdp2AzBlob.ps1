<#
.Synopsis
    Upload Sitecore WDP files into Azure Blob account. This script depends on AzCopy tool. Get the tool from here: http://aka.ms/downloadazcopy
    Once installed the AzCopy is located at %ProgramFiles(x86)%\Microsoft SDKs\Azure\AzCopy or %ProgramFiles%\Microsoft SDKs\Azure\AzCopy

.Example
  .\uploadSoAWdp2AzBlob.ps1 -SourcePath .\xM1 
        -StorageAccountName issccldstrg -ContainerName wdps 
        -DestStorageKey <storageAccountKey> 
        -Pattern '*.scwdp.zip'
.Example
  .\uploadSoAWdp2AzBlob.ps1 -SourcePath .\xM1 
        -StorageAccountName issccldstrg -ContainerName wdps 
        -DestStorageKey <storageAccountKey> -ExtendedParams '/L /V'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] $SourcePath,
    [Parameter(Mandatory=$true)] $StorageAccountName,
    [Parameter(Mandatory=$true)] $ContainerName,
    [Parameter(Mandatory=$true)] $DestStorageKey,
    [Parameter(Mandatory=$false)] $Pattern='*.scwdp.zip',
    [Parameter(Mandatory=$false)] $ExtendedParams
)

function Get-FullBlobPath($destPath, $blobName){
  return $destPath + '/' + $blobName
}

# Clear any existing errors
#$Error.Clear();
# Display error if it occurs
<#
Trap
{
    Write-Host "Error: $($_.Exception.GetType().FullName)" -ForegroundColor Red ; 
    Write-Host $_.Exception.Message; 
    Write-Host $_.Exception.StackTrack;
    break;
}
#>

$DestPath = 'https://' + $StorageAccountName + '.blob.core.windows.net'
if ($ContainerName){
  $DestPath = $DestPath + '/' + $ContainerName
}
Write-Debug "Storage account path: $DestPath"

$azCopyX86 = [Environment]::ExpandEnvironmentVariables("%ProgramFiles(x86)%\Microsoft SDKs\Azure\AzCopy\AzCopy.exe")
$azCopyX64 = [Environment]::ExpandEnvironmentVariables("%ProgramFiles%\Microsoft SDKs\Azure\AzCopy\AzCopy.exe")
$azCopy
if (Test-Path -Path $azCopyX64){
  $azCopy = $azCopyX64
}
if (Test-Path -Path $azCopyX86){
  $azCopy = $azCopyX86
}
if (!(Test-Path -Path $azCopy)){
  Write-Output "AzCopy utility cannot be found. Please install the AzCopy to execute this script."
  exit
}
Write-Debug "AzCopy path: $azCopy"

# If source path starts with '.', convert the relative path into absolute.
if ($SourcePath.StartsWith(".")){
  $SourcePath = $PSScriptRoot + $SourcePath.Substring(1)
  Write-Debug "SourcePath: $SourcePath"
}

try{
#    Write-Host "First line inside Try block"
  [System.Collections.ArrayList]$uploadParams = @("`/Source:$SourcePath", "`/Dest:$DestPath", "`/DestKey:$DestStorageKey")
  if ($Pattern){
    $uploadParams.Add("`/Pattern:$Pattern")
  }
  if ($ExtendedParams){
    $ExtendedParams.Split(' ') | %{$uploadParams.Add($_)}
    #$uploadParams.Add("`/Pattern:$Pattern")
    Write-Debug "ExtendedParams: $ExtendedParams"
  }
  Write-Debug "Full parameters list: $uploadParams"
  &"$azCopy" $uploadParams
  Write-Output "Upload finished"

  # List all files in the container
  $storageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $DestStorageKey

  if ($Pattern){
    $blobs = Get-AzureStorageBlob -Context $storageContext -Container $ContainerName -Blob $Pattern
  }
  else{
    $blobs = Get-AzureStorageBlob -Context $storageContext -Container $ContainerName
  }
  Write-Debug "blob count: $blobs.Count"
  [hashtable]$blobList = @{}
  foreach($blob in $blobs){
    if($blob.Name.Contains("_appcm")){
      $blobList.Add("APPCM", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_appcd")){
      $blobList.Add("APPCD", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_app")){
      $blobList.Add("APP", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif ($blob.Name.Contains("_cm")){
      $blobList.Add("CM", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_cd")){
      $blobList.Add("CD", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_prc")){
      $blobList.Add("PRC", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_rep")){
      $blobList.Add("REP", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    elseif($blob.Name.Contains("_single")){
      $blobList.Add("SINGLE", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
    else{
      $blobList.Add("DEFAULT", $(Get-FullBlobPath $DestPath $blob.Name)) | Out-Null
    }
  }
  #$resourceList = $SourcePath + '\..\' + $ContainerName + '.resourceslist.json'
  @{$ContainerName=$blobList} | ConvertTo-Json | Out-File $($SourcePath + "\..\$ContainerName.resourceslist.json")
  # set azure container ACL to be publicly accessible
  Set-AzureStorageContainerAcl -Container $ContainerName -Context $storageContext -Permission Container
}
catch{
    Write-Error $_.Exception.Message
    Write-Error $_.Exception.StackTrace
}
