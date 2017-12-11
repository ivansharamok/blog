<#
.Synopsis
    Remove all containers based on provided image ID or name.

.Example
  .\clean-docker-containers.ps1 -ImageId my-container

.Example
  .\clean-docker-containers.ps1 -ImageId my-container -RemoveImage
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)] $ImageId,
    [switch] $RemoveImage
)
Write-Host "Removing containers:" -ForegroundColor Green
docker ps -a -q -f ancestor=$ImageId | ForEach-Object{docker rm -f $_}
Write-Host "Done!" -ForegroundColor Green
if ($RemoveImage){
    Write-Host "Removing image $ImageId" -ForegroundColor Green
    docker rmi $ImageId
    Write-Host "Image removed!" -ForegroundColor Green
}