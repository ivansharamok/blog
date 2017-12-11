#!/bin/bash
#
# create solr cores based on provided configuration for Sitecore
# the configuration has to be pre-loaded into /opt/res/config folder
# if configuration is not specified, the cores created from /opt/solr/server/solr/configsets/basic_configs
# exit immediatly if exit command exists with non-zero status
# To create cores for xp configuration type with "sitecore" prefix:
#      docker run -P -d -p 8983:8983 solr create-config-cores.sh
# To create cores for specific configuration type [xm|xp|xp!] with "sitecore" prefix (e.g. sitecore_core_index):
#      docker run -P -d -p 8983:8983 solr create-config-cores.sh xm
# To create cores for specific configuration type [xm|xp|xp!] with custom prefix:
#      docker run -P -d -p 8983:8983 solr create-config-cores.sh xm myprefix
# To create cores for specific configuration type [xm|xp|xp!] with custom prefix and custom index config:
#      docker run -P -d -p 8983:8983 solr create-config-cores.sh xm myprefix /myconfig_dir
set -e
# show script with all parameters passed => $@
echo "Executing $0 $@"
# if VERBOSE output is set, expand commands before execution
if [[ "$VERBOSE" = "yes" ]]; then
    set -x
fi
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
# start solr in foreground
exec solr -f