<#
.Synopsis
    Configures publishing service.

.Example
  .\config-pubservice.ps1

.Example
  .\config-pubservice.ps1 \
        -Core 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_core;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
        -Master 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_master;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
        -Web 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_web;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1'

.Example
  .\config-pubservice.ps1 \
        -Core 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_core;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
        -Master 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_master;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
        -Web 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_web;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
        -Environment development
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $Core='Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_core;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1',
    [Parameter(Mandatory=$false)] $Master='Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_master;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1',
    [Parameter(Mandatory=$false)] $Web='Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_web;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1',
    [Parameter(Mandatory=$false)] $ServicePath='c:\inetpub\wwwroot\sitecorepublishing',
    [Parameter(Mandatory=$false)] $Environment
)
if ($Environment){
    Write-Host "Setting publishing service connection strings for environment `'$Environment`'..."
    # configure core connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'core' $Core '--environment' $Environment}
    # configure web connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'web' $Web '--environment' $Environment}
    # configure master connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'master' $Master '--environment' $Environment}
    Write-Host "Updating publishing service schema..."
    # update pub service database schema
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'schema' 'upgrade' '--force' '--environment' $Environment}
}
else {
    Write-Host "Setting publishing service connection strings..."
    # configure core connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'core' $Core}
    # configure web connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'web' $Web}
    # configure master connection string
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'setconnectionstring' 'master' $Master}
    Write-Host "Updating publishing service schema..."
    # update pub service database schema
    Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'schema' 'upgrade' '--force'}
}