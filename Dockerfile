FROM nikiai/geodesic-base:latest

ENV BANNER "geodesic"

# Where to store state
ENV CACHE_PATH=/localhost/.geodesic

ENV GEODESIC_PATH=/usr/local/include/toolbox
ENV HOME=/conf
ENV KOPS_CLUSTER_NAME=example.foo.bar
ENV SECRETS_PATH=${HOME}

WORKDIR /tmp
#
# Install the simple cloudposse package manager
#
ARG PACKAGES_VERSION=0.1.7
ENV PACKAGES_VERSION ${PACKAGES_VERSION}
RUN git clone --depth=1 -b ${PACKAGES_VERSION} https://github.com/cloudposse/packages.git /packages && rm -rf /packages/.git

#
# Install packges using the package manager
#
ARG PACKAGES="fetch kubectx kubens terragrunt"
ENV PACKAGES ${PACKAGES}
RUN make -C /packages/install ${PACKAGES}


#
# Install github-commenter
#
ENV GITHUB_COMMENTER_VERSION 0.1.0
RUN curl --fail -sSL -o /usr/local/bin/github-commenter https://github.com/cloudposse/github-commenter/releases/download/${GITHUB_COMMENTER_VERSION}/github-commenter_linux_amd64 \
    && chmod +x /usr/local/bin/github-commenter

#
# Install gomplate
#
ENV GOMPLATE_VERSION 2.4.0
RUN curl --fail -sSL -o /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64-slim \
    && chmod +x /usr/local/bin/gomplate

#
# Install Terraform
#
ENV TERRAFORM_VERSION 0.11.7
RUN curl --fail -sSL -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin

#
# Install kubectl
#
ENV KUBERNETES_VERSION=1.9.6
RUN curl --fail -sSL -O https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl completion bash > /etc/bash_completion.d/kubectl.sh
ENV KUBECONFIG=${SECRETS_PATH}/kubernetes/kubeconfig

#
# Install kops
#
ENV KOPS_VERSION 1.9.1
ENV KOPS_STATE_STORE s3://undefined
ENV KOPS_STATE_STORE_REGION ap-south-1
ENV KOPS_FEATURE_FLAGS=+DrainAndValidateRollingUpdate
ENV KOPS_MANIFEST=/conf/kops/manifest.yaml
ENV KOPS_TEMPLATE=/templates/kops/default.yaml
ENV KOPS_BASE_IMAGE=coreos.com/CoreOS-stable-1409.8.0-hvm

ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_PRIVATE_SUBNETS="10.0.1.0/24,10.0.2.0/24,10.0.3.0/24"
ENV KOPS_UTILITY_SUBNETS="10.0.101.0/24,10.0.102.0/24,10.0.103.0/24"
ENV KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"
ENV KUBECONFIG=/dev/shm/kubecfg
RUN curl --fail -sSL -O https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
    && mv kops-linux-amd64 /usr/local/bin/kops \
    && chmod +x /usr/local/bin/kops \
    && /usr/local/bin/kops completion bash > /etc/bash_completion.d/kops.sh

# Instance sizes
ENV BASTION_MACHINE_TYPE "t2.micro"
ENV MASTER_MACHINE_TYPE "t2.medium"
ENV NODE_MACHINE_TYPE "t2.large"

# Min/Max number of nodes (aka workers)
ENV NODE_MAX_SIZE 20
ENV NODE_MIN_SIZE 2

#
# Install sops (required by `helm-secrets`)
#
ARG SOPS_VERSION=3.0.3
RUN curl --fail -sSL -o /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux \
    && chmod +x /usr/local/bin/sops

#
# Install helm
#
ENV HELM_VERSION 2.8.2
ENV HELM_HOME /var/lib/helm
ENV HELM_VALUES_PATH=${SECRETS_PATH}/helm/values
RUN curl --fail -sSL -O http://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64 \
    && chmod +x /usr/local/bin/helm \
    && helm completion bash > /etc/bash_completion.d/helm.sh \
    && mkdir -p ${HELM_HOME} \
    && helm init --client-only \
    && mkdir -p ${HELM_HOME}/plugins \
    && rm -rf helm-v${HELM_VERSION}-linux-amd64.tar.gz;

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
ENV HELM_EDIT_VERSION 0.2.0
ENV HELM_GITHUB_VERSION 0.2.0
ENV HELM_SECRETS_VERSION 1.2.9

RUN helm plugin install https://github.com/app-registry/appr-helm-plugin --version v${HELM_APPR_VERSION} \
    && helm plugin install https://github.com/mstrzele/helm-edit --version v${HELM_EDIT_VERSION} \
    && helm plugin install https://github.com/futuresimple/helm-secrets --version ${HELM_SECRETS_VERSION} \
    && helm plugin install https://github.com/sagansystems/helm-github --version ${HELM_GITHUB_VERSION}

#
# Install helmfile
#
ENV HELMFILE_VENDOR cloudposse
ENV HELMFILE_VERSION 0.13.0-cloudposse
RUN curl --fail -sSL -o /usr/local/bin/helmfile https://github.com/${HELMFILE_VENDOR}/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_linux_amd64 \
    && chmod +x /usr/local/bin/helmfile

# Install Chamber to manage secrets with SSM+KMS
#
ENV CHAMBER_VERSION 2.0.0
RUN curl --fail -sSL -o /usr/local/bin/chamber https://github.com/segmentio/chamber/releases/download/v${CHAMBER_VERSION}/chamber-v${CHAMBER_VERSION}-linux-amd64 \
    && chmod +x /usr/local/bin/chamber

#
# Install goofys
#
ENV GOOFYS_VERSION 0.19.0
RUN curl --fail -sSL -o /usr/local/bin/goofys https://github.com/kahing/goofys/releases/download/v${GOOFYS_VERSION}/goofys \
    && chmod +x /usr/local/bin/goofys

#
# AWS
#
ENV AWS_DATA_PATH=/localhost/.aws/
ENV AWS_CONFIG_FILE=/localhost/.aws/config
ENV AWS_SHARED_CREDENTIALS_FILE=/localhost/.aws/credentials
#
# Install aws cli bundle
#
ENV AWLESS_VERSION="v0.1.10"
RUN if [ -n "${AWLESS_VERSION}" ]; then curl --fail -SL -O https://github.com/wallix/awless/releases/download/${AWLESS_VERSION}/awless-linux-amd64.tar.gz \
    && tar -xzf awless-linux-amd64.tar.gz \
    && rm awless-linux-amd64.tar.gz \
    && mv awless /usr/local/bin \
    && /usr/local/bin/awless completion bash > /etc/bash_completion.d/awless.sh; \
    fi

ENV AWSCLI_VERSION=1.15.10
RUN if [ "${AWSCLI_VERSION}" != "" ]; then \
    pip install --no-cache-dir awscli==${AWSCLI_VERSION} && \
    rm -rf /root/.cache && \
    find / -type f -regex '.*\.py[co]' -delete && \
    ln -s /usr/local/aws/bin/aws_bash_completer /etc/bash_completion.d/aws.sh && \
    ln -s /usr/local/aws/bin/aws_completer /usr/local/bin/; \
    fi

#
# Shell
#
ENV HISTFILE=${CACHE_PATH}/history
ENV XDG_CONFIG_HOME=${CACHE_PATH}

VOLUME ["${CACHE_PATH}"]

COPY rootfs/ /

WORKDIR /conf

CMD ["-c", "bootstrap"]