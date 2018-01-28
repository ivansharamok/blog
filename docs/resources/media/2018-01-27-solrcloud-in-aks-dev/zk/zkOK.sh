#!/usr/bin/env bash

ZK_CLIENT_PORT=${ZK_CLIENT_PORT:-2181}
OK=$(echo ruok | nc 127.0.0.1 $ZK_CLIENT_PORT)

if [[ $OK == "imok" ]]; then 
    # Success
    echo "YES ... $OK"
    exit 0
else
    # Failure
    echo "NO ... $OK"
    exit 1
fi