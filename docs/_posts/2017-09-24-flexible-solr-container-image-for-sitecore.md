---
layout: post
title: Flexible Solr container image for Sitecore
tags: indexing docker
categories: solr containers
date: 2017-09-24
---

* TOC
{:toc}

In article [Solr + SSL in docker container][solr+ssl article] I described how to build an image that always creates exactly same container configuration. That's ideal for environments where configuration is imutable. However, for mutable environments (e.g. development) I want to be able to run different configurations but may not want to build many docker images to support them. This example provides an option how to get a bit more flexible container image to run Solr with Sitecore indexes in a container.  

>TL;TR
Skip all the blabber and go straight to resources: 
* [Dockerfile][dockerfile]
* [create-basic-cores.sh Sitecore 8][create-basic-cores script Sitecore 8]
* [create-basic-cores.sh Sitecore 9][create-basic-cores script Sitecore 9]
* [create-config-cores.sh][create-config-cores script]
* [create-core.sh][create-core script]

>This article assumes the following folder configuration structure for docker build directory:
* /build_dir
  * Dockerfile
  * /res
    * /configs
      * /xm
        * `schema.xml`
        * `solrconfi.xml`
      * /xdb
        * `managed-schema`
    * /scripts
      * `create-basic-cores.sh`
      * `create-basic-cores-sc9.sh`
      * `create-config-cores.sh`
      * `create-core.sh`

## Problem and solution
In my local dev environment I run multiple Sitecore applications that require Solr indexes. Each application has its own set of indexes which may have unique names or configurations. To simplify management of Solr containers to serve different Solr index configurations, I decided to create a docker image that I can pass input parameters to manipulate container state configuration just enough to get me a set of fresh Solr indexes with desired configuration.
>I don't recommed this for production container images. I believe for prod images container configuration can be mutated only at image level.

My solution here is to provide an option to pass a script with parameters to create a container instance. As I shift away from a determined configuration at container image level to container instance, I have to account for container instance state in my scripts. In my example that's to make sure I don't re-create indexes every time a container is stopped and then started. That's because each time you start a contanier instance, it executes input parameters that it received as the instance was created in the first place.

## Prepare Docker image
In this example I moved the part that pre-created Solr index cores described in [Solr + SSL in docker container][solr+ssl article] article and moved it to shell script.

### Input scripts
I created 2 shell scripts to provide options to create Solr cores. One allows me to create cores with these parameters: 
* specified Sitecore confiruation type (xm, xp, xp!)
  * xm - content search cores only (core, master, web, etc.)
  * xp - content search + xdb cores
  * xp! - xdb cores only
* specified core prefix (i.e. myprefix_core_index, myprefix_master_index, etc.)
* specified `schema` (e.g. /shema.xml) file should be used. _When `xm` or `xp` configuration type is used, provides path to schema file for content search cores **only**_. The `xp` and `xp!` configuration types use `schema` from `/opt/res/configs/xp/managed-schema` path.
* specified `solrconfig` file should be used. _Used for content search cores **only**_.
>Explore scipts to see their efault parameters.

### Create basic cores
This script creates Solr cores according to specified configuration type based on `basic_configs` configset and provides options to set core prefixes, custom `schema` (e.g. `/res/configs/xm/my-schema.xml` or `/res/configs/xm/my-managed-schema`) file and custom `solrconfig` (e.g. `/res/configs/my-solrconfig.xml`) file.
#### Script for Sitecore 7.x and 8.x
```bash
# set variables
configpath='/opt/res/configs/xm'
coresdir="/opt/solr/server/solr/mycores"
configsource='/opt/solr/server/solr/configsets/basic_configs'
CONFIG_TYPE=${1:-'xp'}
CORE_PREFIX=${2:-'sitecore'}
SCHEMA=${3:-"$configpath/schema.xml"}
SOLRCONFIG=${4:-"$configpath/solrconfig.xml"}

if [[ -z $SOLR_HOME ]]; then
    coresdir="/opt/solr/server/solr/mycores"
    mkdir -p $coresdir
else
    coresdir=$SOLR_HOME
fi

if [[ 'xp!' != $CONFIG_TYPE ]]; then
    # array of xm core names
    declare -a cores=("${CORE_PREFIX}_core_index" "${CORE_PREFIX}_master_index" 
                        "${CORE_PREFIX}_web_index" "${CORE_PREFIX}_marketingdefinitions_master"
                        "${CORE_PREFIX}_marketingdefinitions_web" "${CORE_PREFIX}_marketing_asset_index_master"
                        "${CORE_PREFIX}_marketing_asset_index_web" "${CORE_PREFIX}_testing_index"
                        "${CORE_PREFIX}_suggested_test_index" "${CORE_PREFIX}_fxm_master_index"
                        "${CORE_PREFIX}_fxm_web_index")
    # create xm cores
    for core in ${cores[@]}; do
        /opt/res/scripts/create-core.sh "${core}"
        cp $SCHEMA ${coresdir}/${core}/conf/schema.xml
        cp $SOLRCONFIG ${coresdir}/${core}/conf/solrconfig.xml
    done
fi

# run this block only for xp || xp! configuration types
if [[ 'xp' == $CONFIG_TYPE ]] || [[ 'xp!' == $CONFIG_TYPE ]]; then
    # array of xdb core names
    declare -a xcores=("${CORE_PREFIX}_xdb" "${CORE_PREFIX}_xdb_rebuild")

    for xcore in ${xcores[@]}; do
        /opt/res/scripts/create-core.sh "${xcore}"
        cp /opt/res/configs/xdb/managed-schema ${coresdir}/${xcore}/conf/managed-schema
    done
fi
```

#### Script for Sitecore 9
```bash
configpath='/opt/res/configs/xm'
coresdir="/opt/solr/server/solr/mycores"
configsource='/opt/solr/server/solr/configsets/basic_configs'
CONFIG_TYPE=${1:-'xp'}
CORE_PREFIX=${2:-'sitecore'}
# do not set default shema path as Sitecore 9.0 and up uses managed-schema file
SCHEMA=${3}
# data_driven_schema_configs has add-unknown-fields-to-the-schema processor enabled by default which is required for managed-schema
SOLRCONFIG=${4:-'/opt/solr/server/solr/configsets/data_driven_schema_configs/conf/solrconfig.xml'}
UNIQUEID=${5:-"_uniqueid"}
FIELDIDTOREPLACE=${6:-"id"}

if [[ -z $SOLR_HOME ]]; then
    coresdir="/opt/solr/server/solr/mycores"
    mkdir -p $coresdir
else
    coresdir=$SOLR_HOME
fi

if [[ 'xp!' != $CONFIG_TYPE ]]; then
    # array of xm core names
    declare -a cores=("${CORE_PREFIX}_core_index" "${CORE_PREFIX}_master_index" 
                        "${CORE_PREFIX}_web_index" "${CORE_PREFIX}_marketingdefinitions_master"
                        "${CORE_PREFIX}_marketingdefinitions_web" "${CORE_PREFIX}_marketing_asset_index_master"
                        "${CORE_PREFIX}_marketing_asset_index_web" "${CORE_PREFIX}_testing_index"
                        "${CORE_PREFIX}_suggested_test_index" "${CORE_PREFIX}_fxm_master_index"
                        "${CORE_PREFIX}_fxm_web_index")
    # create xm cores
    uniquefield="<field name=\"$UNIQUEID\" type=\"string\" indexed=\"true\" stored=\"true\" required=\"true\" multiValued=\"false\" />"
    for core in ${cores[@]}; do
        /opt/res/scripts/create-core.sh "${core}"
        if [[ ! -z $SCHEMA ]]; then
            echo "copying $SCHEMA to ${coresdir}/${core}/conf/managed-schema"
            cp $SCHEMA ${coresdir}/${core}/conf/managed-schema
        else
            # update schema file unique key
            echo "changing <field name=\"$FIELDIDTOREPLACE\"... />"
            sed -i -e "s|<field name=\"$FIELDIDTOREPLACE\".*$|$uniquefield|" ${coresdir}/${core}/conf/managed-schema
            echo "changing <uniqueKey>$FIELDIDTOREPLACE</uniqueKey>"
            sed -i -e "s|<uniqueKey>$FIELDIDTOREPLACE</uniqueKey>$|<uniqueKey>$UNIQUEID</uniqueKey>|" ${coresdir}/${core}/conf/managed-schema
        fi
        if [[ ! -z $SOLRCONFIG ]]; then
            echo "copying $SOLRCONFIG to ${coresdir}/${core}/conf/solrconfig.xml"
            cp $SOLRCONFIG ${coresdir}/${core}/conf/solrconfig.xml
        fi

    done
fi

# run this block only for xp || xp! configuration types
if [[ 'xp' == $CONFIG_TYPE ]] || [[ 'xp!' == $CONFIG_TYPE ]]; then
    # array of xdb core names
    declare -a xcores=("${CORE_PREFIX}_xdb" "${CORE_PREFIX}_xdb_rebuild")

    for xcore in ${xcores[@]}; do
        /opt/res/scripts/create-core.sh "${xcore}"
        cp /opt/res/configs/xdb/managed-schema ${coresdir}/${xcore}/conf/managed-schema
    done
fi
```
Get full code for [create-basic-cores.sh Sitecore 8][create-basic-cores script Sitecore 8] script.  
Get full code for [create-basic-cores-sc9.sh Sitecore 9][create-basic-cores script Sitecore 9] script.
>Sitecore 9 requires managed-schema to be populated with fields before you can start indexing Sitecore items. You can do this by calling `/sitecore/admin/PopulateManagedSchema.aspx?indexes=all` service page.  
As an alternative run [this script][populate managed schema script] after you spin up a new container with fresh Sitecore 9 indexes.

### Create cores based on predefined configufation
Default configset `basic_configs` is a quick way to create a bare bone Solr core. However, a project may require custom Solr core configuraiton with custom stopwords or several languages or else. For this purpose I made another script that creates Solr cores using path that contains custom configuration.
```bash
# set variables
configpath='/opt/res/configs'
coresdir="/opt/solr/server/solr/mycores"
configsource='/opt/solr/server/solr/configsets/basic_configs'
CONFIG_TYPE=${1:-'xp'}
CORE_PREFIX=${2:-'sitecore'}
CONFIG_DIR=${3}

if [[ -z $SOLR_HOME ]]; then
    coresdir="/opt/solr/server/solr/mycores"
    mkdir -p $coresdir
else
    coresdir=$SOLR_HOME
fi
# if config dir is not provide use basic_configs
if [[ -z $CONFIG_DIR ]]; then
    CONFIG_DIR=$configsource
fi

# array of xm core names
if [[ 'xp!' != $CONFIG_TYPE ]]; then
    declare -a cores=("${CORE_PREFIX}_core_index" "${CORE_PREFIX}_master_index" 
                        "${CORE_PREFIX}_web_index" "${CORE_PREFIX}_marketingdefinitions_master"
                        "${CORE_PREFIX}_marketingdefinitions_web" "${CORE_PREFIX}_marketing_asset_index_master"
                        "${CORE_PREFIX}_marketing_asset_index_web" "${CORE_PREFIX}_testing_index"
                        "${CORE_PREFIX}_suggested_test_index" "${CORE_PREFIX}_fxm_master_index"
                        "${CORE_PREFIX}_fxm_web_index")
    # create xm cores
    for core in ${cores[@]}; do
        /opt/res/scripts/create-core.sh "${core}" "${CONFIG_DIR}}"
    done
fi
# run this block only for xp || xp! configuration types
if [[ 'xp' == $CONFIG_TYPE ]] || [[ 'xp!' == $CONFIG_TYPE ]]; then
    # array of xdb core names
    declare -a xcores=("${CORE_PREFIX}_xdb" "${CORE_PREFIX}_xdb_rebuild")

    for xcore in ${xcores[@]}; do
        /opt/res/scripts/create-core.sh "${xcore}" "${CONFIG_DIR}"
    done
fi
```
Get full code for [create-config-cores.sh][create-config-cores script] script.

### *Utility script*
To facilitate index core creation, I use [create-core.sh][create-core script] script. That's where I check for core's existance before I create one.
```bash
# set core variables
CORE=${1:-gettingstarted}
CONFIG_SOURCE=${2:-'/opt/solr/server/solr/configsets/basic_configs'}
if [[ -z $SOLR_HOME ]]; then
    coresdir="/opt/solr/server/solr/mycores"
    mkdir -p $coresdir
else
    coresdir=$SOLR_HOME
fi
# create cores from /configsets/basic_configs
coredir="$coresdir/$CORE"
if [[ ! -d $coredir ]]; then
    cp -r $CONFIG_SOURCE/ $coredir
    touch "$coredir/core.properties"
    echo created "$coredir"
else
    echo "core $CORE already exists"
fi
```

## *Gotchas I ran into*
A few pitfalls I ran into while using Docker on Windows and Mac.

### Set permissions explicitly in Dockerfile
An issue I ran into was the difference in permissions that get assigned to the files when you copy them from local Windows vs Mac OS into docker image. Files copied from Win OS get elevated permissions while files copied from Mac have to be assigned proper permissions to perform necessary actions on them (e.g. execute a shell script). To execute scipts you need `chmod +x` or `chmod 700` permission assigned to shell scripts. Here are instructions in the Dockerfile I had to set the proper permission level:
```docker
# use root user to set permissions
USER root

# other instructions here. See full Dockerfile for more details.

# copy local res directory to /opt/res path in docker image
COPY res /opt/res
# set $SOLR_USER (this variable is a part of original image) ownership for /opt/res path and its contents
RUN chown -R $SOLR_USER:$SOLR_USER /opt/res
# set executable permission for /opt/res contents
RUN chmod -R 700 /opt/res
# set user back to $SOLR_USER
USER $SOLR_USER
```

### Ensure correct end of line sequence (LF vs CRLF)
Since I used Linux based Docker images and run shell scripts in them, I have to make sure my scripts use LF end of line sequence. That's easy to miss when writing shell scripts on Windows. Any modern text editor can change that. To name a few `VS Code`, `Nodepad++`.
One indication you forgot to set proper end of line sequence is this error when you create a container that executes a script:
```
Executing /opt/res/scripts/create-basic-cores.sh xm giddyup
/opt/res/scripts/create-basic-cores.sh: /opt/res/scripts/create-core.sh: /bin/bash^M: bad interpreter: No such file or directory
```

## Examples to create Solr containers with various Sitecore index configurations
Here are a few examples how  you can create containers using input scripts.
### Create Sitecore indexes using all default input parameters
```docker
docker run -d -p 9000:8983 solr create-basic-cores.sh
```
Command creates a container from image named `solr` for `xp` configuration type (i.e. content serach + xdb cores) with prefix `sitecore`, using `/opt/res/configs/xm/schema.xml` schema file and `/opt/res/configs/xm/solrconfig.xml` solrconfig file. It explicitly maps host port `9000` to container port `8983`.

### Create Sitecore indexes for xm configuration only with specified core prefix and specified schema.xml file
```docker
docker run -P -d solr create-basic-cores.sh xm sc82 /opt/res/configs/xm/sc82-schema.xml
```
Command creates a container with Solr cores for `xm` configuration type only (i.e. content search indexes only) with prefix `sc82` (e.g. `sc82_core_index`) and each content search index has schema file based on `/opt/res/configs/xm/sc82-schema.xml`.

### Create Sitecore index for xp configuration only using provided Sorl configuration path
```docker
docker run -P -d solr create-config-cores.sh xp! sc81 /opt/res/configs/xdb/sc81configs
```
Command creates `xp` configuartion indexes only using Solr configuration from path `/opt/res/configs/xdb/sc81configs`.


[solr+ssl article]: {% post_url 2017-09-20-run-solr+ssl-in-docker-container-with-sitecore-indexes %}
[create-basic-cores script Sitecore 8]: {{ "/resources/media/2017-09-24-flexible-solr-container-image-for-sitecore/res/scripts/create-basic-cores.sh" | relative_url }}
[create-basic-cores script Sitecore 9]: {{ "/resources/media/2017-09-24-flexible-solr-container-image-for-sitecore/res/scripts/create-basic-cores-sc9.sh" | relative_url }}
[create-config-cores script]: {{ "/resources/media/2017-09-24-flexible-solr-container-image-for-sitecore/res/scripts/create-config-cores.sh" | relative_url }}
[create-core script]: {{ "/resources/media/2017-09-24-flexible-solr-container-image-for-sitecore/res/scripts/create-core.sh" | relative_url }}
[dockerfile]: {{ "/resources/media/2017-09-24-flexible-solr-container-image-for-sitecore/Dockerfile" | relative_url }}
[populate managed schema script]: https://gist.github.com/ivansharamok/48ce60475d176511eeae16bf254e6dea