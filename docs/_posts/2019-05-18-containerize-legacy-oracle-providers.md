---
layout: post
title: Using Oracle database drivers in Windows containers
tags: mta oracle docker windows
categories: modernize-legacy-app containers windows
date: 2019-05-18
---

* TOC
{:toc}

>TL;TR;
Head to [oracle-drivers][oracle-drivers] folder to view examples of Dockerfiles how to install a specific Oracle driver inside of a Windows container.

## Challenge

In the field I'm seeing a fair number of legacy Windows applications using Oracle database. Many examples I came across had either full blown Oracle client installed or Oracle client runtime version installed. Here are a few patterns I've seen the most:

* Legacy apps built on-demand and customers don't have any source code for them.
* Oracle client with necessary drivers gets installed by means of executing `EXE` distro of the client.
* Apps written in 2000's use quite old Oracle client versions (e.g. versions 8.x/9.x).
* Apps hosted on Win 2000/2003 use 32-bit versions of drivers (e.g. `ODBC`, `OLEDB`).
* Oracle drivers have dependency on Visual C++ Redistributable Package that Microsoft provides.

Obvious question and therefore a challenge is to figure out how to containerize legacy applications that depend on old versions of Oracle drivers without necessity to change the code.

## Approach

>If there is ability to use Oracle Managed.NET driver for .NET apps, by all means DO. It simplifies installation and dependency graph for it is a lot lighter than for native Oracle drivers.

There are several different Oracle drivers packed into Oracle client distro. For instance, `odp.net2`, `odp.net4`, `asp.net2`, `asp.net4`, `odbc`, `oledb`, etc. While it's possible to execute Oracle client `EXE` distro and install entire collection of drivers, standard recommended practice tells us to install only what's necessary for the app and nothing more.
There are 2 main issues I ran into: 

* Minimum Windows version for Windows containers is Windows Server 2016 (WS2016), therefore the minimum version of Oracle client that is supported in Windows containers is `Oracle client 12`.
* Oracle client drivers won't work without proper version of VC++ Redistributable Package. 

Therefore, your course of action should be:

* download and install VC++ Redistributable Package
  * Oracle client 12.2 has dependency on VC++ 2013 redist package ([x86 ver][vc-redist-x86] and [x64 ver][vc-redist-x64]). Make sure to check installation instructions for a particular Oracle client to determine correct version of the dependency package
  * keep in mind that there are 64-bit and 32-bit drivers which require corresponding version of VC++ redist package
  * download and install necessary Oracle client driver

I was able to containerize legacy app with dependency on older Oracle driver versions by installing appropriate Oracle driver from Oracle client 12. I anticipate that in some cases it may not be as simple as this but for me that's all I had to do.

### Installing ODP.NET/ASP.NET driver

This example Dockerfile is parametrized to allow installation of Oracle drivers for different versions of `odp.net` and `asp.net`.

[ASP.NET Dockerfile][oracle-aspnet-df]

<iframe id="frame" src="https://rawcdn.githack.com/ivansharamok/dockerfiles-windows-containers/5b8bb23abba51574bab9651689209fc900097651/oracle-drivers/asp.net/Dockerfile" scrolling="yes"></iframe>

[ODP.NET Dockerfile][oracle-odpnet-df]

<iframe id="frame" src="https://rawcdn.githack.com/ivansharamok/dockerfiles-windows-containers/5b8bb23abba51574bab9651689209fc900097651/oracle-drivers/odp.net/Dockerfile" scrolling="yes"></iframe>

### Installing ODBC driver

This example Dockerfile is parametrized to allow installation of ODBC driver for specified version of Oracle client.
[ODBC Dockerfile][oracle-odbc-df]

### Installing OLEDB driver

[OLEDB Dockerfile][oracle-oledb-df]

## Additional remarks

One issue I ran into was related to anti-virus and threat detection software that blocked `MSI` packages from being installed inside of the containers. In my case the offender was Semantec Endpoint Protection (SEP) software. The solution was to whitelist `msiexec.exe` process in SEP. You can find more details around the issue and troubleshooting Docker file on [MSFT forum][msiexec-av-issue].

## Troubleshooting & testing

Here are a few troubleshooting and testing techniques I employed while researching this topic.

### determine whether VC++ redist package was installed correctly

```Dockerfile
# escape=`
.....
RUN `
  # check whether vc redist 2013 assemblies were installed
  # check physical path for x86 version
  gci -Path C:\Windows\syswow64\* -Include msvcp120*; `
  # check physical path for x64 version
  gci -Path C:\Windows\system32\* -Include msvcp120*; `
  # check Windows registry for VC++ redist package bits
  reg query hklm /s /f msvcp120;
```

### verify ODBC driver was installed and ODBC DSN created

```Dockerfile
# escape=`
.....
RUN `
  # get all ODBC drivers installed in the system
  get-odbcdriver | format-table; `
  # get all ODBC DSNs
  get-odbcdsn;
```

### enable error propagation to browser for Classic ASP apps

Classic ASP framework requires a setting `scriptErrorToBrowser` to be turned on in order to view the error that may occur in the application. Here is example how one can turn that setting on:

```Dockerfile
```

## Resources

* [Docker Reference Architecture: Modernizing Traditional .NET Framework Applications](https://success.docker.com/article/modernizing-traditional-dot-net-applications)
* [MSFT Forum issue discussion](https://forum.microsoft.com)

[oracle-drivers]: https://github.com/ivansharamok/dockerfiles-windows-containers/tree/master/oracle-drivers
[oracle-aspnet-df]: https://github.com/ivansharamok/dockerfiles-windows-containers/blob/master/oracle-drivers/asp.net/Dockerfile
[oracle-odpnet-df]: https://github.com/ivansharamok/dockerfiles-windows-containers/blob/master/oracle-drivers/odp.net/Dockerfile
[oracle-odbc-df]: https://github.com/ivansharamok/dockerfiles-windows-containers/blob/master/oracle-drivers/odbc/Dockerfile
[oracle-oledb-df]: https://github.com/ivansharamok/dockerfiles-windows-containers/blob/master/oracle-drivers/oledb/Dockerfile
[msiexec-av-issue]: https://social.msdn.microsoft.com/Forums/en-US/3c532ac1-e543-4572-ba22-ccdad402f779/service-windows-installer-msiserver-cannot-be-started-inside-of-a-container?forum=windowscontainers
[vc-redist-x86]: http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe
[vc-redist-x64]: http://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe