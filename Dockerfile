FROM public.ecr.aws/codebuild/amazonlinux2-x86_64-standard:5.0 AS core

# Core utilities
RUN set -ex \
    && yum install -y -q openssh-clients \
    && mkdir -p ~/.ssh \
    && mkdir -p /opt/tools \
    && mkdir -p /codebuild/image/config \
    && touch ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H github.com >> ~/.ssh/known_hosts \
    && ssh-keyscan -t rsa,dsa,ed25519,ecdsa -H bitbucket.org >> ~/.ssh/known_hosts \
    && chmod 600 ~/.ssh/known_hosts \
    && yum groupinstall -y -q "Development tools" \
    && yum install -y -q \
        amazon-ecr-credential-helper git wget bzip2 bzip2-devel ncurses ncurses-devel jq \
        libffi-devel sqlite-devel docker \
    && yum install -q -y gnupg2 --best --allowerasing

# repo
RUN curl https://storage.googleapis.com/git-repo-downloads/repo -o /usr/bin/repo \
    && chmod a+rx /usr/bin/repo

# yq
RUN wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq \
    && chmod +x /usr/bin/yq

### End of target: core ### 

FROM core AS tools

# Cleanup
RUN rm -fr /tmp/* /var/tmp/*

# Python
RUN set -ex \
    && pip3 install --no-cache-dir --upgrade --force-reinstall pip \
    && pip3 install --no-cache-dir --upgrade PyYAML setuptools wheel pre-commit

ENV TOOLS_DIR="/usr/local/opt" 

RUN mkdir -p ${TOOLS_DIR}/launch-build-agent
WORKDIR ${TOOLS_DIR}/launch-build-agent/
COPY ./.tool-versions ${TOOLS_DIR}/launch-build-agent/.tool-versions
COPY ./asdf-setup.sh ${TOOLS_DIR}/launch-build-agent/asdf-setup.sh
ENV PATH="$PATH:/root/.asdf"

RUN ${TOOLS_DIR}/launch-build-agent/asdf-setup.sh \
    && pip install launch-cli

### End of target: tools  ### 

FROM tools AS lcaf

ARG GIT_USERNAME \
    GIT_TOKEN \
    GIT_SERVER_URL \
    GIT_ORG \
    GIT_EMAIL_DOMAIN

ENV BUILD_ACTIONS_DIR="${TOOLS_DIR}/launch-build-agent/components/build-actions"

# Install LCAF

RUN git clone "https://${GIT_USERNAME}:${GIT_TOKEN}@${GIT_SERVER_URL}/${GIT_ORG}/git-repo.git" "${TOOLS_DIR}/git-repo" \
    && cd "${TOOLS_DIR}/git-repo" \
    && chmod +x "repo"

ENV PATH="$PATH:${TOOLS_DIR}/git-repo:${BUILD_ACTIONS_DIR}" \
    JOB_NAME="${GIT_USERNAME}" \
    JOB_EMAIL="${GIT_USERNAME}@${GIT_EMAIL_DOMAIN}" \
    PIPELINES_VER="refs/tags/0.1.3" \
    CONTAINER_VER="refs/tags/0.2.0"

ENV IS_PIPELINE=true

COPY "./Makefile" "${TOOLS_DIR}/launch-build-agent/Makefile"

RUN cd /usr/local/opt/launch-build-agent \
    && make git-config \
    && make configure \ 
    && rm -rf $HOME/.gitconfig

### End of target: lcaf  ###
