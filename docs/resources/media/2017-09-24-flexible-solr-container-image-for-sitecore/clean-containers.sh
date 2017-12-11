#!/bin/bash
# remove all containers based on image
IMAGE=${1}
REMOREIMAGE=${2}
docker ps -a | awk '{ print $1,$2 }' | grep $IMAGE | awk '{print $1 }' | xargs -I {} docker -f rm {}
if [[ "rmi" == $REMOREIMAGE ]]; then
    docker rmi $IMAGE -f
fi