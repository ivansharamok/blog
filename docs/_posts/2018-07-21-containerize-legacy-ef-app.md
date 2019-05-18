---
layout: post
title: Solving `password did not match` error while containerizing legacy Entity Framework application
tags: mta dotnet-app docker
categories: modernize-traditional-app containers windows
date: 2018-07-21
---

* TOC
{:toc}

## Story  
I needed to containerize a legacy .NET 3.5 application that used Entity Framework (EF) and [Integrated Windows Authentication][integrated-winauth] (WinAuth) to connect to SQL Server database. Since WinAuth was used, I needed to get [group Managed Service Account][winauth-gmsa](gMSA). However, it often takes time to get gMSA configured by system administrators who govern Active Directory security accounts. A quick workaround was to get a backup of the database and restore it locally using direct database connection bypassing WinAuth.  

> The idea behind [Modernizing Traditional Applications][docker-mta] methodology is to have zero code changes and as few as possible configuration changes to your existing legacy app while moving it into a Docker container. In a nutshell it's similar to `lift-and-shift` approach advertized by cloud providers.

## Discovery
Since gMSA was not ready to be used, a backup of existing database was taken and restored into SQL Server engine running in a Docker container.  

> I used [mssql-server-linux][mssql-server-linux] image for it's small size and Docker's [LCOW container feature][lcow] (available since CE 18.02.0) to run Linux containers side-by-side with Windows containers.

The original app connection string looked like this:
```
<add name="LegacyDbContext" connectionString="Data Source=sqlserver;User Id=NT\dbuser;Initial Catalog=App_Table;MultipleActiveResultSets=true;Integrated Security=SSPI;" providerName="System.Data.SqlClient" />
```
I had to tweak it to include database credentials and disable WinAuth. The result connection string looked like this:
```
<add name="LegacyDbContext" connectionString="Data Source=sqlserver;User Id=dbuser;Password=dbpassword;Initial Catalog=App_Table;MultipleActiveResultSets=true;Integrated Security=false;" providerName="System.Data.SqlClient" />
```
As I launched .NET app in another container, I got YSOD saying that the app couldn't connection to the database with provide credentials. The SQL Server logs showed me the following message:
```
Login failed for user 'dbuser'. Reason: Password did not match that for the login provided.
Error: 18456, Severity: 14, State: 8
```
The error message turned out to be somewhat misleading since I could connect to the database using my credentials via `sqlcmd` utility.

## Solution
I got a hint from my colleague that EF connection string requies one more parameter to allow plain text credentials to be passed: `Persist Security Info=true`. Also found a good explanation of the issue in [stackoverflow post][stackoverflow-ef].  
The resulting connection string that solved the issue looked like this:
```
<add name="LegacyDbContext" connectionString="Data Source=sqlserver;User Id=dbuser;Password=dbpassword;Initial Catalog=App_Table;MultipleActiveResultSets=true;Integrated Security=false;Persist Security Info=true;" providerName="System.Data.SqlClient" />
```

## Additional remarks
Another issue I had to tackle while working on this MTA was related to building a legacy app code inside of a container leveraging [Docker's multistage build][multistage-build] feature.  
The app had a dependency on `Al.exe` which is a part of [NetFxTools](https://docs.microsoft.com/en-us/dotnet/framework/tools/). Typically these tools can be found at `C:\Program Files (x86)\Microsoft SDKs\Windows\` path on a machine that has Visual Studio installed or WindowsSDK tools. I tried to use [microsoft/dotnet-framework:3.5-sdk][msft-dotnet-framework] and [microsoft/dotnet-framework:4.7.2-sdk][msft-dotnet-framework] images to build the app but neither of them had `NetFxTools` installed.  
There are a few possible solutions to this issue:
1. Add installation instruction of `NetFxTools` into the `Dockerfile` for your `build` stage.
2. If WindowsSDK files already exist on your host, you may copy them into `build` stage and set `ToolPath` environment variable to point to `NetFxTools` location within WindowsSDK folder. Dockerfile example:  
{% gist 9277edc1466e78d5bf078ce61df7e635 %}  

Build command for the Dockerfile that explicitly points to Dockerfile location and sets build context to `C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin` where WindowsSDK tools are:  
```
docker build -t netfxtools:4.7.2-sdk -f C:\Users\admin\Documents\projects\netfxtools\Dockerfile 'C:\Program Files (x86)\Microsoft SDKs\Windows\v8.1A\bin'
```

## Resources
* [Docker Reference Architecture: Modernizing Traditional .NET Framework Applications](https://success.docker.com/article/modernizing-traditional-dot-net-applications)
* [Stackoverflow: Persist Security Info Property=true and Persist Security Info Property=false][stackoverflow-ef]
* [Security Considerations (Entity Framework)](https://docs.microsoft.com/en-us/dotnet/framework/data/adonet/ef/security-considerations)

[docker-mta]: https://goto.docker.com/MTAkit.html
[mssql-server-linux]: https://store.docker.com/images/mssql-server-linux
[integrated-winauth]: https://success.docker.com/article/modernizing-traditional-dot-net-applications/#integratedwindowsauthentication
[winauth-gmsa]: https://docs.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/hh831782(v=ws.11)
[lcow]: https://docs.docker.com/docker-for-windows/edge-release-notes/#docker-community-edition-18020-ce-rc1-win50-2018-01-26
[stackoverflow-ef]: https://stackoverflow.com/questions/30419627/persist-security-info-property-true-and-persist-security-info-property-false
[multistage-build]: https://docs.docker.com/develop/develop-images/multistage-build/
[msft-dotnet-framework]: https://hub.docker.com/r/microsoft/dotnet-framework/
