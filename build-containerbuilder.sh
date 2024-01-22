#!/bin/bash
GIT_SERVER_URL=github.com
GIT_ORG=nexient-llc
GIT_USERNAME=foo # Your Bitbucket username here
GIT_TOKEN=bar # Your Bitbucket access token here

set -e
docker buildx build \
    -t launch-build-agent \
    --build-arg GIT_USERNAME="${GIT_USERNAME}" \
    --build-arg GIT_TOKEN="${GIT_TOKEN}" \
    --build-arg GIT_SERVER_URL="${GIT_SERVER_URL}" \
    --build-arg GIT_ORG="${GIT_ORG}" \
    --file ./Dockerfile . \
    --no-cache-filter lcaf \
    --platform linux/amd64 \
    --load


# AWS_PROFILE=launch-root-admin aws ecr get-login-password | docker login --username AWS --password-stdin 538234414982.dkr.ecr.us-east-2.amazonaws.com
docker tag launch-build-agent 538234414982.dkr.ecr.us-east-2.amazonaws.com/launch-build-agent:dev
docker push 538234414982.dkr.ecr.us-east-2.amazonaws.com/launch-build-agent:dev
