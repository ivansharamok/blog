FROM microsoft/windowsservercore
# IMPORTANT: Windows NATing works different in Docker deamon than for Linux containers. Therefore, localhost doesn't bind to docker container by default.
# As a workaround you may use DockerProxy util: https://github.com/docker/for-win/issues/204
LABEL Description="Sitecore Publishing Service 2.1" Vendor="Sitecore" Version="2.1"

# IMPORTANT: any change to a file in /res directory will clear cache for previously built images.
# therefore it's important to move COPY instruction down to as low as possible in Dockerfile.
# /res dir should have publishing service zip. copy resources into container image
COPY res /res
COPY scripts /scripts
# set working directory
WORKDIR /scripts
# download dotnetcore windowshosting into c:\downloads directory
RUN powershell .\install-dotnetcore-winhosting.ps1
#RUN powershell & "C:\\res\\DotNetCore.1.1.0-WindowsHosting.exe" /install /quiet
# install publishing service
RUN powershell .\unpack-pubservice.ps1
# configure default publishing service site
RUN powershell .\config-pubservice.ps1 \
    -Core 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_core;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
    -Master 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_master;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1' \
    -Web 'Data Source=localhost\SQLEXPRESS,1433;Initial Catalog=sitecore_web;Integrated Security=False;User ID=sa;Password=P@ssw0rd1;MultipleActiveResultSets=True;ConnectRetryCount=15;ConnectRetryInterval=1'
# uncomment next line if you want to run publishing service as IIS web site or run the script when creating a container
#RUN powershell .\install-iiswebsite.ps1 -SiteName 'publishing.service' -Port 5001

EXPOSE 5001
#EXPOSE 80
# uncommend ENTRYPOINT when running pub service as IIS web site
#ENTRYPOINT ["powershell .\\get-status.ps1"]
CMD ["powershell .\\start-service.ps1"]