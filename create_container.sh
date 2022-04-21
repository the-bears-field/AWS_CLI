#!/bin/bash

IMAGE_NAME=nodejs:16.14.2
CONTAINER_NAME=aws-cli

docker build -t $IMAGE_NAME .
docker create --env-file .env --name $CONTAINER_NAME -v $PWD:/aws -it $IMAGE_NAME
docker start $CONTAINER_NAME
docker exec -it $CONTAINER_NAME /bin/bash
