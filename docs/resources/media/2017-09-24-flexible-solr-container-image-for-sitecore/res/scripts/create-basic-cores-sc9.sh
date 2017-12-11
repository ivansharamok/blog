#!/bin/bash
#
# create solr cores for Sitecore
# exit immediatly if exit command exists with non-zero status
# To create cores for xp configuration with "sitecore" prefix:
#      docker run -P -d -p 8983:8983 solr create-basic-cores.sh
# To create cores for specific configuration type [xm|xp|xp!] with "sitecore" prefix (e.g. sitecore_core_index):
#      docker run -P -d -p 8983:8983 solr create-basic-cores.sh xm
# To create cores for specific configuration type [xm|xp|xp!] with custom prefix:
#      docker run -P -d -p 8983:8983 solr create-basic-cores.sh xm myprefix
# To create cores for specific configuration type [xm|xp|xp!] with custom prefix and schema:
#      docker run -P -d -p 8983:8983 solr create-basic-cores.sh xm myprefix /managed-schema
# To create cores for specific configuration type [xm|xp|xp!] with custom prefix, schema and solrconfig.xml:
#      docker run -P -d -p 8983:8983 solr create-basic-cores.sh xm myprefix /managed-schema /solrconfig.xml
set -e
# show script with all parameters passed => $@
echo "Executing $0 $@"
# if VERBOSE output is set, expand commands before execution
if [[ "$VERBOSE" = "yes" ]]; then
    set -x
fi

#. /opt/docker-solr/scripts/run-initdb
# set variables
configpath='/opt/res/configs/xm'
coresdir="/opt/solr/server/solr/mycores"
configsource='/opt/solr/server/solr/configsets/basic_configs'
CONFIG_TYPE=${1:-'xp'}
CORE_PREFIX=${2:-'sitecore'}
# do not set default shema path as Sitecore 9.0 and up uses managed-schema file
SCHEMA=${3}
#SOLRCONFIG=${4:-"$configpath/solrconfig.xml"}
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
# start solr in foreground
exec solr -f