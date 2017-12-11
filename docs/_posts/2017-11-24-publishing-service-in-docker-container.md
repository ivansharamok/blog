---
layout: post
title: Sitecore Publishing Service in Docker Windows Container
tags: sitecore publishing docker
categories: publishing containers
date: 2017-11-24
---

* TOC
{:toc}

The article describes how I managed to put [Sitecore Publishing Service][pub-service] into a Docker Windows container. Docker image [microsoft/windowsservercore][winservercore] was used to create an image with the Publishing Service.

>To run Sitecore Publishing Service in a Docker container make sure you switch Docker host to use Windows Containers.

>Image [microsoft/nanoserver][nanoserver] cannot be used as Publishing Service up to version 3.0 has a dependency on `Microsoft.Practices.EnterpriseLibrary.TransientFaultHandling.Data.dll` library which depends on full .NET Framework.

>TL;TR
Skip all the blabber and go straight to resources: 
* [Dockerfile][dockerfile]
* [scripts][scripts]

The scripts provided in this article assume the following folder configuration structure for docker build directory:
* /build_dir
  * Dockerfile
  * /res - contains [Publishing Service][pub-service] zip and [dotnetcore windows hosting][windowshosting] exe.
    * `Sitecore Publishing Service 2.1.0 rev. 171009.zip`
  * /scripts - contains necessary [powershell scripts][scripts] to build the container image and work with Publishing Service.

>You may put [dotnetcore_windowshosting_1_1_0.exe][windowshosting] into `/res` directory to speed up image building process a bit.

## Prepare Docker image
Before building an image make sure you provide valid database connection strings in [Dockerfile][dockerfile]. Dowonload one of Sitecore Publishing Service versions and move service zip into the `/res` dirctory. Downloaded [scripts][scripts] and move them into the `/scripts` directory. Using the [Dockerfile][dockerfile] and [scripts][scripts] run `docker build .` command to create an image with installed Publishing Service in it. 

### Two modes to run Publishing Service
The service can be started as a console app or as an IIS web site.

#### Run it as console app
When running the service as console app over Kestrel web server, there is no need to install `Web-Server` and `Web-Asp-Net45` features. The script [start-service.ps1][start-service] starts the service with 5001 port by default. Inspect the script to understand what parameters it accepts.
>Provided Dockerfile uses `start-service.ps1` script as default command to run the container instance.

#### Run it as IIS web site
When running the service as IIS web site, the Windows features `Web-Server` and `Web-Asp-Net45` must be installed and the service must be configured in IIS. Use script [install-iiswebsite.ps1][install-iiswebsite] to install the features and configure the service in IIS. Inspect the script to understand what parameters it accepts.  
In this mode you must insure that web site worker process starts as you run the container. Otherwise, the container will shut down promptly after you start it. There is [get-status.ps1][get-status] script that pings the publishing service web site. You can use this script to make sure the IIS web site is started after container is created.

## Service logging
Service command logging is stored in `<serviceRoot>\logs` directory. Default service root is set to `c:\inetpub\wwwroot\sitecorepublishing` folder. Publishing logs are stored in differnt places depending on the mode you choose to run the service in.  
When you execute the service as a console app, the logs are stored in current working dirctory. It's set to `/scripts` in the Dockerfile. However, when you run the service as IIS web site, publishing logs go into `<serviceRoot>\logs` directory alongside command logs.

## Utility scripts
There are several scripts provided for this article.
* `config-pubservice.ps1` - allows to configure connection strings for the publishing service and runs database upgrade command on them. You can overwrite default connection strings or configure connection strings for a different envioronment.
* `get-status.ps1` - makes a web request to `http://localhost:5001/api/publishing/operations/status` service page. The output of the request is saved into the `c:\res\status.txt` file. In case of IIS web site, it starts up the publishing service web site.
* `install-iiswebsite.ps1` - installs necessary resources and publishing service as IIS web site. The service is configured to be the default IIS web site running over port 5001.
* `set-custom-connbehaviours.ps1` - provides an example how to configure custom connection behaviors and reconfigure connections to use these connection behaviours.
* `set-custom-logging.ps1` - example how to set custom logging level for publishing service.
* `start-service.ps1` - starts service using Kestrel web server.

## Examples to create containers passing differnt parameters
Here are a few examples how  you can create containers using input scripts.
### Run container using default configuration
```docker
docker run --rm --name pubsvc pubservice21
```
Command creates a container named `pubsvc` from image `pubservice21` and starts publishing service as console app over port 5001. It starts it because Docker file has instruction `CMD ["powershell .\\start-service.ps1"]`.
>Parameter `--rm` instructs docker host to remove container when it stops runnig.

### Run container and configure connection strings
```docker
docker run --rm --name pubsvc pubservice21 powershell ".\\config-pubservice.ps1 -Core '<coreConnectionString>' -Master '<masterConnectionString>' -Web '<webConnectionString>'; .\\start-service.ps1"
```
Command creates a container and configures connection strings provided in the parameters. Then executes `start-service.ps1` script to get the service runing as a console app.

### Run service as IIS web site
```docker
docker run --rm --name pubsvc pubservice21 powershell ".\\install-iiswebsite.ps1; .\\get-status.ps1"
```
Command creates container with publishing service configured as IIS web site. Then invokes `get-status.ps1` script to get web site running.

### Reconfigure running service
You can execute scripts to re-configure the publishing service when you attach to already running container.
```docker
docker exec -it pubsvc powershell
```
Command attaches to container `pubsvc` and opens `powershell` console. From here you can navigate around container file system and execute scripts to re-configure the service if needed.

## Gotchas
Some issues I ran into while building and testing the container.

### Copying files between host and container
Several times I was not able to copy files into and out of the container until I stopped the container.

### localhost mapping
Windows containers use different approach to configure container network than Linux containers. One outcome of this is that `localhost` [does not map to Windows container](https://github.com/docker/for-win/issues/204) by default. You can use either direct IP address of the container or utility [DockerProxy][dockerproxy].
Get container IP address:
```bash
{% raw %}
docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <containerId>
{% endraw %}
```

### Installing windows hosting sometimes fails
Several times I got error message while .net core windows hosting was getting installed.
```
hcsshim::ImportLayer failed in Win32: The system cannot find the path specified. (0x3) layerId=\\?\C:\ProgramData\Docker\windowsfilter
```
There seems to be an [issue](https://github.com/moby/moby/issues/32838) related to the file system in Windows docker containers. Re-running image build command solved the problem.


[pub-service]: https://dev.sitecore.net/Downloads/Sitecore_Publishing_Service.aspx
[winservercore]: https://hub.docker.com/r/microsoft/windowsservercore/
[nanoserver]: https://hub.docker.com/r/microsoft/nanoserver/
[dockerfile]: {{ "/resources/media/2017-11-24-publishing-service-in-docker-container/Dockerfile" | relative_url }}
[scripts]: {{ "/resources/media/2017-11-24-publishing-service-in-docker-container/scripts" | prepend: site.github_blog_root }}
[windowshosting]: https://aka.ms/dotnetcore_windowshosting_1_1_0
[start-service]: {{ "/resources/media/2017-11-24-publishing-service-in-docker-container/scripts/start-service.ps1" | relative_url }}
[install-iiswebsite]: {{ "/resources/media/2017-11-24-publishing-service-in-docker-container/scripts/install-iiswebsite.ps1" | relative_url }}
[get-status]: {{ "/resources/media/2017-11-24-publishing-service-in-docker-container/scripts/get-status.ps1" | relative_url }}
[dockerproxy]: https://github.com/Kymeric/DockerProxy