#!/bin/bash
#
# create solr cores for Sitecore 9.0
# exit immediatly if exit command exists with non-zero status
set -e
# show script with all parameters passed => $@
echo "Executing $0 $@"
# if VERBOSE output is set, expand commands before execution
if [[ "$VERBOSE" = "yes" ]]; then
    set -x
fi
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