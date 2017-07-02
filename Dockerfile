FROM alpine:3.4

RUN apk update \
    && apk add unzip curl tar \
          python make bash vim jq \
          openssl openssh-client iputils drill \
          git coreutils less groff bash-completion hub hub-bash-completion && \
          mkdir /etc/bash_completion.d/
	  
RUN echo "0" > /proc/sys/net/ipv6/conf/all/disable_ipv6

USER root

WORKDIR /tmp

# Install Terraform
ENV TERRAFORM_VERSION 0.9.5
RUN curl --fail -sSL -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin

# Install kubectl
ENV KUBERNETES_VERSION 1.5.2
RUN curl --fail -sSL -O https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl completion bash > /etc/bash_completion.d/kubectl.sh

# Install kops
ENV KOPS_VERSION 1.5.1
RUN curl --fail -sSL -O https://github.com/kubernetes/kops/releases/download/${KOPS_VERSION}/kops-linux-amd64 \
    && mv kops-linux-amd64 /usr/local/bin/kops \
    && chmod +x /usr/local/bin/kops \
    && /usr/local/bin/kops completion bash > /etc/bash_completion.d/kops.sh

# Install helm
ENV HELM_VERSION 2.3.1
RUN curl --fail -sSL -O http://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64 \
    && chmod +x /usr/local/bin/helm \
    && helm completion > /etc/bash_completion.d/helm.sh

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
ENV GCLOUD_SDK_VERSION=147.0.0
RUN curl --fail -sSL -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    tar -zvxf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    mv google-cloud-sdk /usr/local/ && \
    /usr/local/google-cloud-sdk/install.sh --quiet --rc-path /etc/bash_completion.d/gcloud.sh && \
    rm -rf google-cloud-sdk-${GCLOUD_SDK_VERSION}-linux-x86_64.tar.gz && \
    rm -rf /root/.config/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gcloud /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/gsutil /usr/local/bin/ && \
    ln -s /usr/local/google-cloud-sdk/bin/bq /usr/local/bin/

ENV AWSEBCLI_VERSION 3.10.1
RUN apk add py-pip && \
    pip install awsebcli==${AWSEBCLI_VERSION} --upgrade && \
    rm -rf /root/.cache && \
    find / -type f -regex '.*\.py[co]' -delete

ENV BOOTSTRAP=true

# Where to store state
ENV LOCAL_MOUNT_POINT=/mnt/local
ENV LOCAL_STATE=/mnt/local
ENV REMOTE_MOUNT_POINT=/mnt/remote
ENV REMOTE_STATE=/mnt/remote/geodesic

ENV GEODESIC_PATH=/usr/local/include/toolbox
ENV MOTD_URL=http://geodesic.sh/motd
ENV HOME=/mnt/local

VOLUME ["/mnt/local"]

ADD aws-assumed-role/profile /etc/profile.d/aws-assume-role.sh
ADD rootfs/ /

WORKDIR /mnt/local

ENTRYPOINT ["/bin/bash", "-l"]

