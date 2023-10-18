#!/bin/bash
GIT_SERVER_URL=github.com
GIT_ORGANIZATION=nexient-llc
GIT_USERNAME=foo # Your Bitbucket username here
GIT_TOKEN=bar # Your Bitbucket access token here

set -e
docker buildx build \
    -t caf-build-agent \
    --build-arg GIT_USERNAME="${GIT_USERNAME}" \
    --build-arg GIT_TOKEN="${GIT_TOKEN}" \
    --build-arg GIT_SERVER_URL="${GIT_SERVER_URL}" \
    --build-arg GIT_ORGANIZATION="${GIT_ORGANIZATION}" \
    --file ./Dockerfile . \
    --no-cache-filter caf \
    --platform linux/amd64 \
    --load


# AWS_PROFILE=launch aws ecr get-login-password | docker login --username AWS --password-stdin 778189110199.dkr.ecr.us-east-2.amazonaws.com
docker tag caf-build-agent 778189110199.dkr.ecr.us-east-2.amazonaws.com/caf-build-agent:dev
docker push 778189110199.dkr.ecr.us-east-2.amazonaws.com/caf-build-agent:dev
