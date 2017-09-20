# Run Solr + SSL in Docker container with Sitecore indexes
The idea here is to run Solr component configured with SSL in its own Docker container that could be used in local development environment.

> TL;TR  
Don't want to go thru step by step exerciese, then here is [complete Dockerfile](./resources/media/run-solr+ssl-in-docker-container-with-sitecore-indexes/Dockerfile) for this article.

## Create Docker image
The fastest way to create a Solr docker image is to build it from [already available Solr images](https://hub.docker.com/_/solr/). In this example I use image [solr:6.6-alpine](https://github.com/docker-solr/docker-solr/tree/c61a0c9b012c7313c2b5d0d97ddc06693270b734/6.6/alpine).

>I use Linix based containers for this exercise. Do appropriate switching of Docker engine if you run Docker on Windows.

### Docker image preparation considerations
Building my own version from an existing image makes sense when I want to change something in the original image or perpahs provide a differnt command or script for an `ENTRYPOINT` or `CMD`. In this exercise I want to configure Solr with SSL using the image that does not do that. If you just starting with docker images, you may find it tempting to put desired container configuration into shell scripts and then run them via `ENTRYPOINT` or `CMD` or combination of both. While that's possible to do, I believe it's contrary to what containers usually used for. In dev environment containers typically run as stateless components that can be destroyed at any time and re-created with exact same configuration state.  
Having said that there could be situations when you may need to have a statefull container which could be stopped and started many times. In those cases you do need to be carefull what logic you put into `ENTRYPOINT` and `CMD` commands as that logic will run **every time** when you create or start a container.

### Create basic Dockerfile
Create a `Dockerfile` in a folder with the following content to make a Solr docker image based on lighweight [docker alpine linux version](https://hub.docker.com/_/alpine/).
```Dockerfile
FROM solr:6.6-alpine

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]
```
> Scripts `docker-entrypoint.sh` and `solr-foreground` come from original [solr:6.6-alpine](https://github.com/docker-solr/docker-solr/tree/8a8e9311fbe5d40861f6d26293441c272a7878f8/6.6) image. For more info on docker `ENTRYPOINT` and `CMD` refer to [official docker docs](https://docs.docker.com/engine/reference/builder/#understand-how-cmd-and-entrypoint-interact).

Building this `Dockerfile` will pull `solr:6.6-alpine` image and build it into your local docker repository. So far this configuration doesn't provide any benefits to me as I just build my local image from already available container. In this case creating a Solr container from my local image would be similar to simply running a docker command:
```
docker run --name <myContainerName> -p 8983:8983 solr:6.6-alpine
```
### Generate SSL cert
To generate SSL certificate I use [keytool](https://docs.oracle.com/javase/8/docs/technotes/tools/unix/keytool.html) that is supplied with Java platform. 

>The code below as well as following bits of code will go into the `Dockerfile` between lines `FROM` and `ENTRYPOINT`.

```Dockerfile
ENV SOLR_SSL_PATH /opt/solr/server/etc/solr-ssl.keystore.jks
ENV SOLR_SSL_PWD secret
# create SSL certificate
RUN set -e; \
    $JAVA_HOME/bin/keytool -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $SOLR_SSL_PWD -storepass $SOLR_SSL_PWD \
    -validity 9999 -keystore $SOLR_SSL_PATH -ext SAN=DNS:localhost,IP:127.0.0.1 \
    -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"; \
    exit 0
```
### Set Solr SSL parameters
Next step is to configure Solr SSL parameters with the certificate keystore. For that I need to configure SSL parameters in `/solr.in.sh` file.
```Dockerfile
# set Solr SSL parameters
RUN sed -i -e "s|#SOLR_SSL_KEY_STORE=.*$|SOLR_SSL_KEY_STORE=$SOLR_SSL_PATH|" /opt/solr/bin/solr.in.sh && \
    sed -i -e "s/#SOLR_SSL_KEY_STORE_PASSWORD=.*$/SOLR_SSL_KEY_STORE_PASSWORD=$SOLR_SSL_PWD/" /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_KEY_STORE_TYPE=.*$/SOLR_SSL_KEY_STORE_TYPE=JKS/' /opt/solr/bin/solr.in.sh && \
    sed -i -e "s|#SOLR_SSL_TRUST_STORE=.*$|SOLR_SSL_TRUST_STORE=$SOLR_SSL_PATH|" /opt/solr/bin/solr.in.sh && \
    sed -i -e "s/#SOLR_SSL_TRUST_STORE_PASSWORD=.*$/SOLR_SSL_TRUST_STORE_PASSWORD=$SOLR_SSL_PWD/" /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_TRUST_STORE_TYPE=.*$/SOLR_SSL_TRUST_STORE_TYPE=JKS/' /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_NEED_CLIENT_AUTH=.*$/SOLR_SSL_NEED_CLIENT_AUTH=false/' /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_WANT_CLIENT_AUTH=.*$/SOLR_SSL_WANT_CLIENT_AUTH=false/' /opt/solr/bin/solr.in.sh
```
>When a variable contains special characters that are used as a separator for `sed` shell command, you must use a different separator character. In this example I use `|` separator for commands that use `SOLR_SSL_PATH` variable.

### *Copy local resources into the docker image [OPTIONAL]*
I build my Solr image with certain Solr configuration. For that I've configured my `solrconfig.xml` in a certain way and prepared my `schema.xml` file.
>For example, I want to force Solr instance to use `schema.xml` file by configuring `<schemaFactory class="ClassicIndexSchemaFactory" />` in `solrconfig.xml`)

```Dockerfile
COPY res /opt/res
```
In this example I'm copying my local `res` folder and all of its contents located in the same directory as `Dockerfile` onto the `/opt/res` path in my docker image. My `res` folder structure looks like this:
```
/res
    /configs
        /solrconfig-6.6.0.xml
        /schema-6.6.0.xml
        /managed-schema-6.6.0
```
### Pre-create Solr cores
In my case I know upfront what Solr indexes I will need to run my application. Therefore I pre-create all necessary Solr index cores to make them available once Solr instance starts.
```Dockerfile
ENV CORE_PREFIX 'myproject'
ENV CORES_DIR '/opt/solr/server/solr/mycores'
ENV CONFIG_SOURCE '/opt/solr/server/solr/configsets/basic_configs'

# create CORES_DIR if it doesn't exist
RUN if [[ -z $CORES_DIR ]]; then \
        mkdir -p $CORES_DIR; \
    fi

ENV XM_CORE_NAMES "${CORE_PREFIX}_core_index, ${CORE_PREFIX}_master_index, ${CORE_PREFIX}_web_index, ${CORE_PREFIX}_marketingdefinitions_master, ${CORE_PREFIX}_marketingdefinitions_web, ${CORE_PREFIX}_marketing_asset_index_master, ${CORE_PREFIX}_marketing_asset_index_web, ${CORE_PREFIX}_testing_index, ${CORE_PREFIX}_suggested_test_index, ${CORE_PREFIX}_fxm_master_index, ${CORE_PREFIX}_fxm_web_index"
# create xm index cores
RUN set -e; \
    ORIG_IFS=${IFS}; \
    IFS=', '; \
    for core in ${XM_CORE_NAMES}; do \
        cp -r $CONFIG_SOURCE/ $CORES_DIR/$core; \
        touch "$CORES_DIR/$core/core.properties"; \
        echo created "$CORES_DIR/$core"; \
        cp /opt/res/configs/xm/schema-6.6.0.xml ${CORES_DIR}/${core}/conf/schema.xml; \
        cp /opt/res/configs/xm/solrconfig-6.6.0.xml ${CORES_DIR}/${core}/conf/solrconfig.xml; \
    done; \
    IFS=${ORIG_IFS}; \
    exit 0

ENV XP_CORE_NAMES "${CORE_PREFIX}_xdb, ${CORE_PREFIX}_xdb_rebuild"
# create xp index cores
RUN set -e; \
    ORIG_IFS=${IFS}; \
    IFS=', '; \
    for xcore in ${XP_CORE_NAMES}; do \
        cp -r $CONFIG_SOURCE/ $CORES_DIR/$xcore; \
        touch "$CORES_DIR/$xcore/core.properties"; \
        echo created "$CORES_DIR/$xcore"; \
        cp /opt/res/configs/xdb/managed-schema-6.6.0 ${CORES_DIR}/${xcore}/conf/managed-schema; \
    done; \
    IFS=${ORIG_IFS}; \
    exit 0

```
I use Solr `basic_configs` to pre-create my index cores. If a custom set of configs is required, you can put it into the `res` folder and then modify the script to use those configs instead.
>Some of my indexes use `schema.xml` and some use `managed-schema`. In Solr 6.6.x I don't have to supply my own `solrconfig.xml` for indexes that use `managed-schema` as Solr 6.6 uses managed schema by default.

### Build docker image
Once all `Dockerfile` instructions are in place, I need to build my image to add it to my local repository. Image can be build with the following command executed within the directory that contains `Dockerfile`:
```
docker build -t my-solr-image .
```
>In case you name `Dockerfile` something else, you have to supply that file to the `docker build` instruction. See [official docker doc](https://docs.docker.com/engine/reference/commandline/build/#build-with-path) on this.
```
docker build -t my-solr-image -f /path/to/dockerfile-dev .
```
All images that you pull or build are added to local repository. To see all images run this command:
```
docker images
```
## Run docker container from my image
To create a container from an image, run `docker run` command:
```
docker run --name my-solr-container -p 8983:8983 my-solr-image
```
This command will create a docker container titled `my-solr-container` from image `my-solr-image` and will map host port 8983 to docker port 8983. Once container is up and running, I can open my browser and connect to my Solr instance at `https://localhost:8983/solr`.
>Depending on browser you may need to add exception for SSL certificate when you navigate to Solr instance as your CA may not recognize it.
## *Additional commands, notes, scripts*
A few additional notes and commands on the subject that I used while working with docker containers.
### List all Docker containers
List all running containers
```
docker ps
```
List all existing containers
```
docker ps -a
```
Get just IDs of all existing containers
```
docker ps -a -q
```
### Remove all containers based on certain image
```CMD
docker ps -a -q -f ancestor=my-solr-image | %{docker rm -f $_}
```
>Complete PowerShell script available [here](./resources/media/run-solr+ssl-in-docker-container-with-sitecore-indexes/clean-docker-containers.ps1).

