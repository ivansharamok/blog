<#
.Synopsis
    Sets custom connection behaviours for publishing service.

.Example
  .\set-custom-connbehaviours.ps1

.Example
  .\set-custom-connbehaviours.ps1 -ServicePath 'c:\inetpub\wwwroot\sitecorepublishing' -BackoffStrategy 'sql-expobackoff' -Environment development
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)] $ServicePath='c:\inetpub\wwwroot\sitecorepublishing',
    [Parameter(Mandatory=$false)] $FileName='sc.custom.config.json',
    [Parameter(Mandatory=$false)] $BackoffStrategy='sql-fixedbackoff',
    [Parameter(Mandatory=$false)] $Environment
)
if ($Environment){
  Write-Host "Setting custom db connection behaviours..."
  # fixed backoff strategy
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
    'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Type' `
    '-v' 'Sitecore.Framework.Publishing.Data.AdoNet.FixedBackoffDbConnectionBehaviour`1[[Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.SqlDatabaseTransientErrorDetectionStrategy, Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data]], Sitecore.Framework.Publishing.Data' `
    '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:Name' '-v' 'SQL Fixed Backoff' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:CommandTimeout' '-v' '15' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:RetryCount' '-v' '3' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:RetryIntervalSeconds' '-v' '300' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:FirstFastRetry' '-v' 'true' `
  '-f' $FileName '--environment' $Environment}  
  # exponential backoff strategy
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Type' `
  '-v' 'Sitecore.Framework.Publishing.Data.AdoNet.ExponentialBackoffDbConnectionBehaviour`1[[Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.SqlDatabaseTransientErrorDetectionStrategy, Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data]], Sitecore.Framework.Publishing.Data' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:Name' '-v' 'SQL Exponential Backoff' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:CommandTimeout' '-v' '300' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:RetryCount' '-v' '5' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:MinBackoffSeconds' '-v' '0' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:MaxBackoffSeconds' '-v' '60' `
  '-f' $FileName '--environment' $Environment}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:DeltaBackoffSeconds' '-v' '5' `
  '-f' $FileName '--environment' $Environment}  
}
else {
  # db connection behaviours
  # fixed backoff strategy
  Write-Host "Setting custom db connection behaviours..."
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Type' `
  '-v' 'Sitecore.Framework.Publishing.Data.AdoNet.FixedBackoffDbConnectionBehaviour`1[[Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.SqlDatabaseTransientErrorDetectionStrategy, Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data]], Sitecore.Framework.Publishing.Data' '-f' $FileName}
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:Name' '-v' 'SQL Fixed Backoff' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:CommandTimeout' '-v' '300' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:RetryCount' '-v' '3' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:RetryIntervalSeconds' '-v' '30' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-fixedbackoff:Options:FirstFastRetry' '-v' 'true' '-f' $FileName}  

  # exponential backoff strategy
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Type' `
  '-v' 'Sitecore.Framework.Publishing.Data.AdoNet.ExponentialBackoffDbConnectionBehaviour`1[[Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.SqlDatabaseTransientErrorDetectionStrategy, Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data]], Sitecore.Framework.Publishing.Data' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:Name' '-v' 'SQL Exponential Backoff' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:CommandTimeout' '-v' '300' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:RetryCount' '-v' '5' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:MinBackoffSeconds' '-v' '0' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:MaxBackoffSeconds' '-v' '60' '-f' $FileName}  
  Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
  'Sitecore:Publishing:Services:DbConnectionBehaviours:Options:Entries:sql-expobackoff:Options:DeltaBackoffSeconds' '-v' '5' '-f' $FileName}  
}
# db connections
Write-Host "Setting custom db connections..."
# Links
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Links:Options:Behaviours:backend' '-v' $BackoffStrategy '-f' $FileName}  
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Links:Options:Behaviours:api' '-v' $BackoffStrategy '-f' $FileName}  
# Service
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Service:Options:Behaviours:backend' '-v' $BackoffStrategy '-f' $FileName}  
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Service:Options:Behaviours:api' '-v' $BackoffStrategy '-f' $FileName}  
# Master
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Master:Options:Behaviours:backend' '-v' $BackoffStrategy '-f' $FileName}  
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Master:Options:Behaviours:api' '-v' $BackoffStrategy '-f' $FileName}  
# Internet
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Internet:Options:Behaviours:backend' '-v' $BackoffStrategy '-f' $FileName}  
Invoke-Command -ScriptBlock {& "$ServicePath\Sitecore.Framework.Publishing.Host.exe" 'configuration' 'set' `
'Sitecore:Publishing:Services:DefaultConnectionFactory:Options:Connections:Internet:Options:Behaviours:api' '-v' $BackoffStrategy '-f' $FileName}  