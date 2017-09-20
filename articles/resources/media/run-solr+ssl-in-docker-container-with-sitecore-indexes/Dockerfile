FROM solr:6.6-alpine

ENV SOLR_SSL_PATH /opt/solr/server/etc/solr-ssl.keystore.jks
ENV SOLR_SSL_PWD secret
# create SSL certificate
RUN set -e; \
    $JAVA_HOME/bin/keytool -genkeypair -alias solr-ssl -keyalg RSA -keysize 2048 -keypass $SOLR_SSL_PWD -storepass $SOLR_SSL_PWD \
    -validity 9999 -keystore $SOLR_SSL_PATH -ext SAN=DNS:localhost,IP:127.0.0.1 \
    -dname "CN=localhost, OU=Organizational Unit, O=Organization, L=Location, ST=State, C=Country"; \
    exit 0

# set Solr SSL parameters
RUN sed -i -e "s|#SOLR_SSL_KEY_STORE=.*$|SOLR_SSL_KEY_STORE=$SOLR_SSL_PATH|" /opt/solr/bin/solr.in.sh && \
    sed -i -e "s/#SOLR_SSL_KEY_STORE_PASSWORD=.*$/SOLR_SSL_KEY_STORE_PASSWORD=$SOLR_SSL_PWD/" /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_KEY_STORE_TYPE=.*$/SOLR_SSL_KEY_STORE_TYPE=JKS/' /opt/solr/bin/solr.in.sh && \
    sed -i -e "s|#SOLR_SSL_TRUST_STORE=.*$|SOLR_SSL_TRUST_STORE=$SOLR_SSL_PATH|" /opt/solr/bin/solr.in.sh && \
    sed -i -e "s/#SOLR_SSL_TRUST_STORE_PASSWORD=.*$/SOLR_SSL_TRUST_STORE_PASSWORD=$SOLR_SSL_PWD/" /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_TRUST_STORE_TYPE=.*$/SOLR_SSL_TRUST_STORE_TYPE=JKS/' /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_NEED_CLIENT_AUTH=.*$/SOLR_SSL_NEED_CLIENT_AUTH=false/' /opt/solr/bin/solr.in.sh && \
    sed -i -e 's/#SOLR_SSL_WANT_CLIENT_AUTH=.*$/SOLR_SSL_WANT_CLIENT_AUTH=false/' /opt/solr/bin/solr.in.sh

# copy local resource into docker image
COPY res /opt/res

ENV CORE_PREFIX 'myproject'
ENV CORES_DIR '/opt/solr/server/solr/mycores'
ENV CONFIG_SOURCE '/opt/solr/server/solr/configsets/basic_configs'

# create CORES_DIR path if it doesn't exist
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

# reuse ENTRYPOINT and CMD from original image
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]