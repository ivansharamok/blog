FROM openjdk:8-jre-alpine

ENV ZK_USER=zk \
  ZK_HOME=/zk \
  ZK_DATA_DIR=/zk_data \
  ZK_DATALOG_DIR=/zk_datalog \
  ZK_LOG_DIR=/zk_log

ARG DIST_URL=http://www.apache.org/dist/
ARG VERSION=3.4.11
ARG ZK_DIST=zookeeper-${VERSION}

LABEL name="zookeeper" version=${VERSION}

RUN apk add --no-cache wget bash gnupg

RUN set -x pipefail \
  && wget --quiet "${DIST_URL}/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz" \
  && wget --quiet "${DIST_URL}/zookeeper/$ZK_DIST/$ZK_DIST.tar.gz.asc" \
  && wget --quiet "${DIST_URL}/zookeeper/KEYS" \
  && export GNUPGHOME="$(mktemp -d)" \
  && gpg --import KEYS \
  && gpg --batch --verify "$ZK_DIST.tar.gz.asc" "$ZK_DIST.tar.gz" \
  && mkdir -p opt \
  && tar --extract --file="$ZK_DIST.tar.gz"  --directory=/opt \
  && rm -rf "$GNUPGHOME" "$ZK_DIST.tar.gz" "$ZK_DIST.tar.gz.asc" \
  && rm -rf /opt/$ZK_DIST/CHANGES.txt \
    /opt/$ZK_DIST/README.txt \
    /opt/$ZK_DIST/NOTICE.txt \
    /opt/$ZK_DIST/CHANGES.txt \
    /opt/$ZK_DIST/README_packaging.txt \
    /opt/$ZK_DIST/build.xml \
    /opt/$ZK_DIST/config \
    /opt/$ZK_DIST/contrib \
    /opt/$ZK_DIST/dist-maven \
    /opt/$ZK_DIST/docs \
    /opt/$ZK_DIST/ivy.xml \
    /opt/$ZK_DIST/ivysettings.xml \
    /opt/$ZK_DIST/recipes \
    /opt/$ZK_DIST/src \
    /opt/$ZK_DIST/$ZK_DIST.jar.asc \
    /opt/$ZK_DIST/$ZK_DIST.jar.md5 \
    /opt/$ZK_DIST/$ZK_DIST.jar.sha1

# Copy configuration generator and setup scripts to bin and make executable
COPY zkGenConfig.sh zkOK.sh zkMetrics.sh "/opt/$ZK_DIST/bin/"

# Create a user for the zookeeper process and configure file system ownership 
# for nessecary directories and modify scripts as a user executable
RUN set -x pipefail \
  && mkdir -p $ZK_DATA_DIR $ZK_DATALOG_DIR $ZK_LOG_DIR \
  #&& groupadd --gid 1000 $ZK_USER \
  && addgroup -S -g 1000 $ZK_USER \
  #&& useradd --uid 1000 --gid $ZK_USER --home $ZK_HOME $ZK_USER \
  && adduser -S -H -s /sbin/nologin -u 1000 -g $ZK_USER -h $ZK_HOME $ZK_USER \
  && ln -s -v /opt/$ZK_DIST $ZK_HOME \
  && ln -s -v $ZK_DATA_DIR $ZK_HOME$ZK_DATA_DIR \
  && ln -s -v $ZK_DATALOG_DIR $ZK_HOME$ZK_DATALOG_DIR \
  && ln -s -v $ZK_LOG_DIR $ZK_HOME$ZK_LOG_DIR \
  && chown -R -L "$ZK_USER:$ZK_USER" $ZK_HOME \
  && chmod +x "$ZK_HOME/bin/zkGenConfig.sh" "$ZK_HOME/bin/zkOK.sh" "$ZK_HOME/bin/zkMetrics.sh"
  
# Set working directory to zk home
WORKDIR $ZK_HOME

# Set non-root user on container start
USER 1000