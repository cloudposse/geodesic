FROM alpine:3.6

RUN apk update \
    && apk add unzip curl tar \
          python make bash vim jq figlet \
          openssl openssh-client sshpass iputils drill \
          gcc libffi-dev python-dev musl-dev openssl-dev py-virtualenv \
          git coreutils less groff bash-completion && \
          mkdir -p /etc/bash_completion.d/ /etc/profile.d/

RUN echo "net.ipv6.conf.all.disable_ipv6=0" > /etc/sysctl.d/00-ipv6.conf

USER root

WORKDIR /tmp

# Install Terraform
ENV TERRAFORM_VERSION 0.10.8
RUN curl --fail -sSL -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin

# Install kubectl
ENV KUBERNETES_VERSION 1.7.10
RUN curl --fail -sSL -O https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl completion bash > /etc/bash_completion.d/kubectl.sh

# Install kops
ENV KOPS_VERSION 1.7.1
ENV KOPS_STATE_STORE s3://undefined
ENV KOPS_STATE_STORE_REGION us-east-1
ENV AWS_SDK_LOAD_CONFIG=1
ENV KOPS_FEATURE_FLAGS=+DrainAndValidateRollingUpdate
ENV KOPS_MANIFEST=/conf/kops/manifest.yaml
ENV KOPS_TEMPLATE=/templates/kops/default.yaml

# https://github.com/kubernetes/kops/blob/master/channels/stable
# https://github.com/kubernetes/kops/blob/master/docs/images.md
ENV KOPS_BASE_IMAGE=kope.io/k8s-1.7-debian-jessie-amd64-hvm-ebs-2017-07-28

ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_PRIVATE_SUBNETS="172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19"
ENV KOPS_UTILITY_SUBNETS="172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22"
ENV KUBECONFIG=/dev/shm/kubecfg
RUN curl --fail -sSL -O https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
    && mv kops-linux-amd64 /usr/local/bin/kops \
    && chmod +x /usr/local/bin/kops \
    && /usr/local/bin/kops completion bash > /etc/bash_completion.d/kops.sh

# Instance sizes
ENV BASTION_MACHINE_TYPE "t2.medium"
ENV MASTER_MACHINE_TYPE "t2.medium"
ENV NODE_MACHINE_TYPE "t2.medium"

# Min/Max number of nodes (aka workers)
ENV NODE_MAX_SIZE 2
ENV NODE_MIN_SIZE 2

# Install helm
ENV HELM_VERSION 2.7.0
ENV HELM_HOME /var/lib/helm
RUN curl --fail -sSL -O http://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64 \
    && chmod +x /usr/local/bin/helm \
    && helm completion bash > /etc/bash_completion.d/helm.sh \
    && mkdir -p ${HELM_HOME} \
    && helm init --client-only \
    && helm plugin install https://github.com/mstrzele/helm-edit \
    && helm plugin install https://github.com/app-registry/appr-helm-plugin \
    && helm repo add cloudposse-incubator https://charts.cloudposse.com/incubator/ \
    && helm repo update

# Install packer
ENV PACKER_VERSION 1.1.1
RUN curl --fail -sSL -O https://releases.hashicorp.com/packer/${PACKER_VERSION}/packer_${PACKER_VERSION}_linux_amd64.zip \
    && unzip packer_${PACKER_VERSION}_linux_amd64.zip \
    && rm packer_${PACKER_VERSION}_linux_amd64.zip \
    && mv packer /usr/local/bin

# Install aws cli bundle
RUN curl --fail -sSL -O https://s3.amazonaws.com/aws-cli/awscli-bundle.zip \
    && unzip awscli-bundle.zip \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm awscli-bundle.zip \
    && rm -rf awscli-bundle \
    && ln -s /usr/local/aws/bin/aws_bash_completer /etc/bash_completion.d/aws.sh \
    && ln -s /usr/local/aws/bin/aws_completer /usr/local/bin/

# Install S3FS
# Overrride URI for AWS Metadata API so we can run outside of AWS using a hardcoded path on the filesystem :)
ENV S3FS_VERSION 1.80
RUN apk --update add fuse libxml2 mailcap && \
    apk --virtual .build-deps add alpine-sdk automake autoconf libxml2-dev fuse-dev curl-dev && \
	git clone https://github.com/s3fs-fuse/s3fs-fuse.git && \
    cd s3fs-fuse && \
    git checkout tags/v${S3FS_VERSION} && \
    ./autogen.sh && \
    ./configure --prefix=/usr && \
    sed -i -E 's!http://169.254.169.254.*?/!file:///mnt/local/aws/cli/cache/!g' src/curl.cpp && \
    make && \
    make install && \
    apk del .build-deps

# Install Google Cloud SDK
ENV GCLOUD_SDK_VERSION=179.0.0
RUN curl --fail -sSL -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar -zvxf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    mv google-cloud-sdk /usr/local/ && \
    /usr/local/google-cloud-sdk/install.sh --quiet --rc-path /etc/bash_completion.d/gcloud.sh && \
    rm -rf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm -rf /root/.config/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gsutil /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/bq /usr/local/bin/

# Install AWS CLI
ENV AWSEBCLI_VERSION 3.12.0
RUN apk add py-pip && \
    pip install awsebcli==${AWSEBCLI_VERSION} --upgrade && \
    rm -rf /root/.cache && \
    find / -type f -regex '.*\.py[co]' -delete

# Install Ansible
ENV ANSIBLE_VERSION 2.4.1.0
ENV JINJA2_VERSION 2.10
RUN pip install ansible==${ANSIBLE_VERSION} boto Jinja2==${JINJA2_VERSION} --upgrade && \
    rm -rf /root/.cache && \
    find / -type f -regex '.*\.py[co]' -delete

# Install gomplate
ENV GOMPLATE_VERSION 2.2.0
RUN curl --fail -sSL -o /usr/local/bin/gomplate https://github.com/hairyhenderson/gomplate/releases/download/v${GOMPLATE_VERSION}/gomplate_linux-amd64-slim \
    && chmod +x /usr/local/bin/gomplate

# Install AWS Assumed Role
ENV AWS_ASSUMED_ROLE_VERSION 0.1.0
RUN curl --fail -sSL -o /etc/profile.d/aws-assume-role.sh https://raw.githubusercontent.com/cloudposse/aws-assumed-role/0.1.0/profile \
    && chmod +x /etc/profile.d/aws-assume-role.sh

ENV BANNER "geodesic"

# Where to store state
ENV LOCAL_MOUNT_POINT=/mnt/local
ENV LOCAL_STATE=/mnt/local
ENV REMOTE_MOUNT_POINT=/mnt/remote
ENV REMOTE_STATE=/mnt/remote/geodesic

ENV GEODESIC_PATH=/usr/local/include/toolbox
ENV MOTD_URL=http://geodesic.sh/motd
ENV HOME=/mnt/local

VOLUME ["/mnt/local"]
VOLUME ["/mnt/remote"]

ADD rootfs/ /

WORKDIR /mnt/local

ENTRYPOINT ["/bin/bash"]
CMD ["-c", "bootstrap"]
