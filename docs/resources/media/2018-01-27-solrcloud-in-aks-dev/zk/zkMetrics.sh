#!/usr/bin/env bash

ZK_CLIENT_PORT=${ZK_CLIENT_PORT:-2181}
echo mntr | nc localhost $ZK_CLIENT_PORT >& 1