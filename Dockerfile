ARG LAUNCH_PROVIDER="az"

FROM ubuntu:24.04 AS core

# Core utilities
RUN set -ex \
    && apt-get update \
    && apt-get install -y \
        zip unzip wget bzip2 curl git jq yq \
        libffi-dev libncurses5-dev libsqlite3-dev libssl-dev libicu-dev \
        python-is-python3 python3-venv python3-pip \
        ca-certificates openssh-client build-essential docker.io gnupg2

# Set up SSH for git and bitbucket
RUN mkdir -p ~/.ssh \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts

FROM core AS tools

ARG LAUNCH_CLI_VERSION="0.5.0"

RUN python -m venv env \
    && . env/bin/activate \
    && pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir --upgrade PyYAML setuptools awscli wheel \
    && pip install --no-cache-dir "launch-cli==${LAUNCH_CLI_VERSION}"

# repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/bin/repo \
    && chmod a+rx /usr/bin/repo

# Cleanup
RUN rm -fr /tmp/* /var/tmp/*

FROM tools AS lcaf

ARG GIT_USERNAME="nobody" \
    GIT_EMAIL_DOMAIN="nttdata.com" \
    REPO_TOOL="https://github.com/launchbynttdata/git-repo.git"

# Environment variables
ENV TOOLS_DIR="/usr/local/opt" \
    IS_PIPELINE=true

# Create work directory
RUN mkdir -p ${TOOLS_DIR}/launch-build-agent
WORKDIR ${TOOLS_DIR}/launch-build-agent/

# Install asdf
# TODO: migrate to mise.
COPY ./.tool-versions ${TOOLS_DIR}/launch-build-agent/.tool-versions
COPY ./scripts/asdf-setup.sh ${TOOLS_DIR}/launch-build-agent/asdf-setup.sh
RUN ${TOOLS_DIR}/launch-build-agent/asdf-setup.sh
ENV PATH="$PATH:/root/.asdf/bin:/root/.asdf/shims"

# Install launch's modified git-repo
RUN git clone "${REPO_TOOL}" "${TOOLS_DIR}/git-repo" \
    && cd "${TOOLS_DIR}/git-repo" \
    && export PATH="$PATH:${TOOLS_DIR}/git-repo" \
    && chmod +x "repo"

FROM lcaf AS lcaf-provider-aws
# Make configure here brings all the AWS shell script actions. 
# This can be deprecated when all the actions are moved to the launch-cli

# Run make configure
COPY "./Makefile" "${TOOLS_DIR}/launch-build-agent/Makefile"
ENV BUILD_ACTIONS_DIR="${TOOLS_DIR}/launch-build-agent/components/build-actions" \
    PATH="$PATH:${BUILD_ACTIONS_DIR}" \
    JOB_NAME="${GIT_USERNAME}" \
    JOB_EMAIL="${GIT_USERNAME}@${GIT_EMAIL_DOMAIN}"
RUN cd /usr/local/opt/launch-build-agent \
    && make git-config \
    && make configure \ 
    && rm -rf $HOME/.gitconfig

FROM lcaf as lcaf-provider-az
# This is needed to set up the build agent in use on a private AKS cluster

ENV AGENT_ALLOW_RUNASROOT="true" \
    TARGETARCH="linux-x64"

WORKDIR /azp/

COPY ./scripts/az-entry.sh  /azp/az-entry.sh

RUN chmod +x /azp/az-entry.sh \
    && curl -sL -o InstallAzureCLIDeb.sh https://aka.ms/InstallAzureCLIDeb \
    && chmod +x InstallAzureCLIDeb.sh \
    && ./InstallAzureCLIDeb.sh \
    && rm -f InstallAzureCLIDeb.sh

ENTRYPOINT ["/bin/bash", "-c", " /azp/az-entry.sh"]

FROM lcaf-provider-${LAUNCH_PROVIDER} AS final

RUN echo "Built image for: ${LAUNCH_PROVIDER}"