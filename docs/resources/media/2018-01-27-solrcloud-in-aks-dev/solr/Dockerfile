FROM solr:6.6-alpine
# use root user to set permissions
USER root

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
#CMD ["solr-foreground"]
CMD ["solr -f -c -z zkapp-0:2181 zkapp-1:2181 zkapp-2:2181"]
