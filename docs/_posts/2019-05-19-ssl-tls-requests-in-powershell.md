---
layout: post
title: Working with SSL/TLS resources in Windows containers
tags: shell docker windows
categories: modernize-legacy-app containers windows
date: 2019-05-19
---

* TOC
{:toc}

## PITA

This is more of shell related issue but I see it often to be a confusing and frustrating issue when building a container image. The issue is when one needs to access a resource over HTTPS protocol, Powershell can throw an error similar to this:

```powershell
PS C:\> Invoke-WebRequest -Uri 'https://repo.contoso.com'
Invoke-WebRequest : The request was aborted: Could not create SSL/TLS secure channel.
At line:1 char:1
+ Invoke-WebRequest -Uri 'https://repo.contoso.com'
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : InvalidOperation: (System.Net.HttpWebRequest:HttpWebRequest) [Invoke-WebRequest], WebExc
   eption
    + FullyQualifiedErrorId : WebCmdletWebResponseException,Microsoft.PowerShell.Commands.InvokeWebRequestCommand
```

The issue here is that Powershell has TLS 1.0 set as its `SecurityProtocol`. When a remote server enforses TLS 1.1, 1.2 or higher, you can get the error requesting HTTPS resource.

## Solution

The solution would be different depending on the base image you use `servercore` or `nanoserver`.

### servercore

The `servercore` has full blown Powershell (PS) (at least at this moment but PS Core is closing in on it fast). In full version of PS, one can change `SecurityProtocol` setting to allow different version of TLS/SSL protocol to be used `Invoke-WebRequest` a.k.a. `iwr` a.k.a. `curl`.
Here is how you can set it to use `TLS 1.2`:

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Tls12'
```

One can also tell PS to respect a number of known security protocols at the same time:

```powershell
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]'Ssl3,Tls,Tls11,Tls12'
```

Once SSL/TLS issue is out of the way, you may still encounter an error like this:

```powershell
PS C:\> iwr -Uri 'https://repo.contoso.com'
iwr : The response content cannot be parsed because the Internet Explorer engine is not available, or Internet
Explorer's first-launch configuration is not complete. Specify the UseBasicParsing parameter and try again.
At line:1 char:1
+ iwr -Uri 'https://repo.contoso.com'
+ ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotImplemented: (:) [Invoke-WebRequest], NotSupportedException
    + FullyQualifiedErrorId : WebCmdletIEDomNotSupportedException, Microsoft.PowerShell.Commands.InvokeWebRequestCommand
```

Follow the suggestion in the error message and add `UseBasicParsing` flag to your `Invoke-WebRequest` command:

```powershell
PS C:\> (iwr -Uri 'https://repo.contoso.com' -UseBasicParsing).StatusCode
200
```

Now the command should succeed (unless your container inside enterprise domain that [requires proxy](use-proxy) to access the Internet resources).

>Things are a bit easier with Powershell Core (PSCore) 6+ where `SkipCertificateCheck` was added to ease work with HTTPS resources. I think it should be analogous to `curl -k` on Linux.

### nanoserver

While `nanoserver` image looks attractive with it's small (in Windows world) size, its shell options somewhat weak. The `nanoserver` based on core `10.0.14393` (WS 2016) gives you a _lean_ version of `Powershell` (Powershell Core) and good ol' `CMD`. The Powershell Core (PSCore) has very limited set of commands and settings comparing to full version in `servercore`. For instance, there is no `[System.Net.ServicePointManager]::SecurityProtocol` setting available to tweak TLS version. Newer versions of `nanoserver` have no PS shell as they are optimized for `.NET Core` applications.
However, Microsoft maintains an image of `nanoserver` which does include PSCore. If don't feel like learning batch scripting and hacking your way through `CMD` shell, I'd recommend to look into one of the [mcr.microsoft.com/powershell](https://hub.docker.com/_/microsoft-powershell) images.

With PSCore 6+ one can request HTTPS resource like this:

```powershell
iwr -SkipCertificateCheck -Uri 'https://repo.contoso.com'
```

## Disable SSL/TLS certificate verification

There is no easy way to disable cert verification in Powershell. The only way I found to disable the check involves a script posted on [stackoverflow post][disable-ssl-check]. While the script worked in `servercore` image, it failed for me in `nanoserver:10.0.14393.XXXX` image.
Couldn't find a way around it in `nanoserver` except for using [PSCore 6+][pscore-releases] where `iwr` has a flag `SkipCertificateCheck`.

## Resources

* [Disable certificate verification in Powershell][disable-ssl-check]
* [Docker Reference Architecture: Modernizing Traditional .NET Framework Applications](https://success.docker.com/article/modernizing-traditional-dot-net-applications)
* [Changes to Nano Server](https://docs.microsoft.com/en-us/windows-server/get-started/nano-in-semi-annual-channel)

[use-proxy]: https://github.com/ivansharamok/dockerfiles-windows-containers/tree/master/pull-resources-via-proxy
[disable-ssl-check]: https://stackoverflow.com/questions/46855241/ignoring-self-signed-certificates-from-powershell-invoke-restmethod-doesnt-work
[pscore-releases]: https://github.com/PowerShell/PowerShell/releases
