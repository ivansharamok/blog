FROM solr:6.6.0-alpine
# use root user to set permissions
USER root

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

COPY res /opt/res
# set $SOLR_USER (this variable is a part of original image) ownership for /opt/res path and its contents
RUN chown -R $SOLR_USER:$SOLR_USER /opt/res
# set executable permission for /opt/res
RUN chmod -R 700 /opt/res

# add /opt/res/scripts to PATH
ENV PATH /opt/res/scripts:$PATH
# set user back to $SOLR_USER
USER $SOLR_USER
# reuse ENTRYPOINT and CMD from original image
ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["solr-foreground"]
