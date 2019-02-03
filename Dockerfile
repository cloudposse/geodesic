#
# Python Dependencies
#
FROM alpine:3.8 as python

RUN sed -i 's|http://dl-cdn.alpinelinux.org|https://alpine.global.ssl.fastly.net|g' /etc/apk/repositories
RUN apk add python python-dev libffi-dev gcc py-pip py-virtualenv linux-headers musl-dev openssl-dev make

COPY requirements.txt /requirements.txt

RUN pip install -r /requirements.txt --install-option="--prefix=/dist" --no-build-isolation

#
# Google Cloud SDK
#
FROM google/cloud-sdk:228.0.0-alpine as google-cloud-sdk

#
# Cloud Posse Package Distribution
#
FROM cloudposse/packages:0.70.0 as packages

WORKDIR /packages

#
# Install the select packages from the cloudposse package manager image
#
# Repo: <https://github.com/cloudposse/packages>
#
ARG PACKAGES="cfssl cfssljson"
ENV PACKAGES=${PACKAGES}
RUN make dist


#
# Geodesic base image
#
FROM alpine:3.8

ENV BANNER "geodesic"

# Where to store state
ENV CACHE_PATH=/localhost/.geodesic

ENV GEODESIC_PATH=/usr/local/include/toolbox
ENV MOTD_URL=http://geodesic.sh/motd
ENV HOME=/conf
ENV KOPS_CLUSTER_NAME=example.foo.bar

# Install all packages as root
USER root

# Install the cloudposse alpine repository
ADD https://apk.cloudposse.com/ops@cloudposse.com.rsa.pub /etc/apk/keys/
RUN echo "@cloudposse https://apk.cloudposse.com/3.8/vendor" >> /etc/apk/repositories

# Use TLS for alpine default repos
RUN sed -i 's|http://dl-cdn.alpinelinux.org|https://alpine.global.ssl.fastly.net|g' /etc/apk/repositories && \
    echo "@testing https://alpine.global.ssl.fastly.net/alpine/edge/testing" >> /etc/apk/repositories && \
    echo "@community https://alpine.global.ssl.fastly.net/alpine/edge/community" >> /etc/apk/repositories && \
    apk update

# Install alpine package manifest
COPY packages.txt /etc/apk/

RUN apk add --update $(grep -v '^#' /etc/apk/packages.txt) && \
    mkdir -p /etc/bash_completion.d/ /etc/profile.d/ /conf && \
    ln -s /usr/share/bash-completion/completions/fzf /etc/bash_completion.d/fzf.sh && \
    touch /conf/.gitconfig

RUN echo "net.ipv6.conf.all.disable_ipv6=0" > /etc/sysctl.d/00-ipv6.conf

# Disable vim from reading a swapfile (incompatible with goofys)
RUN echo 'set noswapfile' >> /etc/vim/vimrc

WORKDIR /tmp

# Copy python dependencies
COPY --from=python /dist/ /usr/

# Copy installer over to make package upgrades easy
COPY --from=packages /packages/install/ /packages/install/

# Copy select binary packages
COPY --from=packages /dist/ /usr/local/bin/

#
# Install Google Cloud SDK
#
ENV CLOUDSDK_CONFIG=/localhost/.config/gcloud/

COPY --from=google-cloud-sdk /google-cloud-sdk/ /usr/local/google-cloud-sdk/

RUN ln -s /usr/local/google-cloud-sdk/completion.bash.inc /etc/bash_completion.d/gcloud.sh && \
    ln -s /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gsutil /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/bq /usr/local/bin/ && \
    gcloud config set core/disable_usage_reporting true --installation && \
    gcloud config set component_manager/disable_update_check true --installation && \
    gcloud config set metrics/environment github_docker_image --installation

#
# Configure aws-vault to easily assume roles (not related to HashiCorp Vault)
#
ENV AWS_VAULT_ENABLED=true
ENV AWS_VAULT_BACKEND=file
ENV AWS_VAULT_ASSUME_ROLE_TTL=1h
#ENV AWS_VAULT_FILE_PASSPHRASE=

#
# Configure aws-okta to easily assume roles
#
ENV AWS_OKTA_ENABLED=false

#
# Install kubectl
#
ENV KUBERNETES_VERSION 1.10.11
ENV KUBECONFIG=${SECRETS_PATH}/kubernetes/kubeconfig
RUN kubectl completion bash > /etc/bash_completion.d/kubectl.sh
ENV KUBECTX_COMPLETION_VERSION 0.6.2
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubens.bash /etc/bash_completion.d/kubens.sh
ADD https://raw.githubusercontent.com/ahmetb/kubectx/v${KUBECTX_COMPLETION_VERSION}/completion/kubectx.bash /etc/bash_completion.d/kubectx.sh

#
# Install kops
#
ENV KOPS_STATE_STORE s3://undefined
ENV KOPS_STATE_STORE_REGION us-east-1
ENV KOPS_FEATURE_FLAGS=+DrainAndValidateRollingUpdate
ENV KOPS_MANIFEST=/conf/kops/manifest.yaml
ENV KOPS_TEMPLATE=/templates/kops/default.yaml

# https://github.com/kubernetes/kops/blob/master/channels/stable
# https://github.com/kubernetes/kops/blob/master/docs/images.md
ENV KOPS_BASE_IMAGE=kope.io/k8s-1.10-debian-jessie-amd64-hvm-ebs-2018-08-17

ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_PRIVATE_SUBNETS="172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19"
ENV KOPS_UTILITY_SUBNETS="172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KUBECONFIG=/dev/shm/kubecfg
RUN /usr/bin/kops completion bash > /etc/bash_completion.d/kops.sh

# Instance sizes
ENV BASTION_MACHINE_TYPE "t2.medium"
ENV MASTER_MACHINE_TYPE "t2.medium"
ENV NODE_MACHINE_TYPE "t2.medium"

# Min/Max number of nodes (aka workers)
ENV NODE_MAX_SIZE 2
ENV NODE_MIN_SIZE 2

#
# Install helm
#
ENV HELM_HOME /var/lib/helm
ENV HELM_VALUES_PATH=${SECRETS_PATH}/helm/values
RUN helm completion bash > /etc/bash_completion.d/helm.sh \
    && mkdir -p ${HELM_HOME} \
    && helm init --client-only \
    && mkdir -p ${HELM_HOME}/plugins

#
# Install helm repos
#
RUN helm repo add cloudposse-incubator https://charts.cloudposse.com/incubator/ \
    && helm repo add incubator  https://kubernetes-charts-incubator.storage.googleapis.com/ \
    && helm repo add coreos-stable https://s3-eu-west-1.amazonaws.com/coreos-charts/stable/ \
    && helm repo update

#
# Install helm plugins
#
ENV HELM_APPR_VERSION 0.7.0
ENV HELM_DIFF_VERSION 2.11.0+2
ENV HELM_EDIT_VERSION 0.2.0
ENV HELM_GITHUB_VERSION 0.2.0
ENV HELM_SECRETS_VERSION 1.2.9
ENV HELM_S3_VERSION 0.7.0
ENV HELM_PUSH_VERSION 0.7.1

RUN helm plugin install https://github.com/app-registry/appr-helm-plugin --version v${HELM_APPR_VERSION} \
    && helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} \
    && helm plugin install https://github.com/mstrzele/helm-edit --version v${HELM_EDIT_VERSION} \
    && helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION} \
    && helm plugin install https://github.com/sagansystems/helm-github --version ${HELM_GITHUB_VERSION} \
    && helm plugin install https://github.com/hypnoglow/helm-s3 --version v${HELM_S3_VERSION} \
    && helm plugin install https://github.com/chartmuseum/helm-push --version v${HELM_PUSH_VERSION}

# 
# Install fancy Kube PS1 Prompt
#
ENV KUBE_PS1_VERSION 0.6.0
ADD https://raw.githubusercontent.com/jonmosco/kube-ps1/${KUBE_PS1_VERSION}/kube-ps1.sh /etc/profile.d/prompt:kube-ps1.sh

#
# AWS
#
ENV AWS_DATA_PATH=/localhost/.aws/
ENV AWS_CONFIG_FILE=${AWS_DATA_PATH}/config
ENV AWS_SHARED_CREDENTIALS_FILE=${AWS_DATA_PATH}/credentials

#
# Shell
#
ENV HISTFILE=${CACHE_PATH}/history
ENV SHELL=/bin/bash
ENV LESS=-Xr
ENV SSH_AGENT_CONFIG=/var/tmp/.ssh-agent

# Reduce `make` verbosity
ENV MAKEFLAGS="--no-print-directory"
ENV MAKE_INCLUDES="Makefile Makefile.*"

# This is not a "multi-user" system, so we'll use `/etc` as the global configuration dir
# Read more: <https://wiki.archlinux.org/index.php/XDG_Base_Directory>
ENV XDG_CONFIG_HOME=/etc

# Clean up file modes for scripts
RUN find ${XDG_CONFIG_HOME} -type f -name '*.sh' -exec chmod 755 {} \;

COPY rootfs/ /

WORKDIR /conf

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "init"]
