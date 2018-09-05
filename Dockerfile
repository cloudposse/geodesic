FROM alpine:3.8 as python

COPY requirements.txt /requirements.txt
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories
RUN apk add python python-dev libffi-dev gcc py-pip py-virtualenv linux-headers musl-dev openssl-dev make
RUN pip install -r /requirements.txt --install-option="--prefix=/dist"

FROM cloudposse/packages:0.24.0 as packages

WORKDIR /packages

#
# Install the select packages from the cloudposse package manager image
#
# Repo: <https://github.com/cloudposse/packages>
#
ARG PACKAGES="awless aws-vault cfssl cfssljson chamber fetch figurine github-commenter gomplate goofys helm helmfile kops kubectl kubectx kubens sops stern terraform terragrunt yq shellcheck shfmt"
ENV PACKAGES=${PACKAGES}
RUN make dist

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

# oath-toolkit
# https://www.nongnu.org/oath-toolkit/
# https://www.nongnu.org/oath-toolkit/oathtool.1.html
RUN sed -i 's/http\:\/\/dl-cdn.alpinelinux.org/https\:\/\/alpine.global.ssl.fastly.net/g' /etc/apk/repositories \
    && echo "@testing https://alpine.global.ssl.fastly.net/alpine/edge/testing" >> /etc/apk/repositories

# Install common packages
ARG APK_PACKAGES="unzip curl tar python make bash vim jq figlet openssl openssh-client sshpass \
                 iputils drill musl-dev ncurses \
                 git coreutils less groff bash-completion fuse syslog-ng libc6-compat util-linux libltdl \
                 oath-toolkit-oathtool@testing"

ENV APK_PACKAGES=${APK_PACKAGES}

RUN apk update \
    && apk add ${APK_PACKAGES} \
    && mkdir -p /etc/bash_completion.d/ /etc/profile.d/ \
    && mkdir -p /conf \
    && touch /conf/.gitconfig

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
# Install aws-vault to easily assume roles (not related to HashiCorp Vault)
#
ENV AWS_VAULT_BACKEND file
ENV AWS_VAULT_ASSUME_ROLE_TTL=1h
#ENV AWS_VAULT_FILE_PASSPHRASE=

#
# Install kubectl
#
ENV KUBERNETES_VERSION 1.9.1
ENV KUBECONFIG=${SECRETS_PATH}/kubernetes/kubeconfig
RUN kubectl completion bash > /etc/bash_completion.d/kubectl.sh

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
ENV KOPS_BASE_IMAGE=kope.io/k8s-1.9-debian-jessie-amd64-hvm-ebs-2018-03-11

ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_PRIVATE_SUBNETS="172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19"
ENV KOPS_UTILITY_SUBNETS="172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KUBECONFIG=/dev/shm/kubecfg
RUN /usr/local/bin/kops completion bash > /etc/bash_completion.d/kops.sh

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
ENV HELM_DIFF_VERSION 2.10.0+1
ENV HELM_EDIT_VERSION 0.2.0
ENV HELM_GITHUB_VERSION 0.2.0
ENV HELM_SECRETS_VERSION 1.2.9

RUN helm plugin install https://github.com/app-registry/appr-helm-plugin --version v${HELM_APPR_VERSION} \
    && helm plugin install https://github.com/databus23/helm-diff --version v${HELM_DIFF_VERSION} \
    && helm plugin install https://github.com/mstrzele/helm-edit --version v${HELM_EDIT_VERSION} \
    && helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION} \
    && helm plugin install https://github.com/sagansystems/helm-github --version ${HELM_GITHUB_VERSION}

#
# Install Google Cloud SDK
#
ENV GCLOUD_SDK_VERSION=214.0.0
RUN curl --fail -sSL -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar -zxf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    mv google-cloud-sdk /usr/local/ && \
    /usr/local/google-cloud-sdk/install.sh --quiet --rc-path /etc/bash_completion.d/gcloud.sh && \
    rm -rf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm -rf /root/.config/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gsutil /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/bq /usr/local/bin/

#
# Install bats-core for automated testing
# https://github.com/bats-core/bats-core
#
ENV BATS_CORE_VERSION=1.1.0
RUN curl --fail -sSL -O https://github.com/bats-core/bats-core/archive/v${BATS_CORE_VERSION}.tar.gz && \
    tar -C /tmp -zxf v${BATS_CORE_VERSION}.tar.gz && \
    /tmp/bats-core-${BATS_CORE_VERSION}/install.sh /usr/local && \
    rm -rf v${BATS_CORE_VERSION}.tar.gz && \
    rm -rf /tmp/bats-core-${BATS_CORE_VERSION}

#
# AWS
#
ENV AWS_DATA_PATH=/localhost/.aws/
ENV AWS_CONFIG_FILE=/localhost/.aws/config

#
# Shell
#
ENV HISTFILE=${CACHE_PATH}/history
ENV SHELL=/bin/bash
ENV LESS=-Xr
ENV XDG_CONFIG_HOME=${CACHE_PATH}
ENV SSH_AGENT_CONFIG=/var/tmp/.ssh-agent

COPY rootfs/ /

WORKDIR /conf

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "bootstrap"]
