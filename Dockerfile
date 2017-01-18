FROM alpine:latest

RUN apk update \
		&& apk add unzip curl tar python make bash vim jq openssl openssh-client iputils drill git

USER root

WORKDIR /tmp

# Install Terraform
ENV TERRAFORM_VERSION 0.7.7
RUN curl -sSL -O https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && rm terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    && mv terraform /usr/local/bin

# Install kubectl
ENV KUBERNETES_VERSION 1.5.1
RUN curl -sSL -O https://storage.googleapis.com/kubernetes-release/release/v${KUBERNETES_VERSION}/bin/linux/amd64/kubectl \
    && mv kubectl /usr/local/bin/kubectl \
    && chmod +x /usr/local/bin/kubectl

# Install kops
ENV KOPS_VERSION 1.4.4
RUN curl -sSL -O https://github.com/kubernetes/kops/releases/download/v${KOPS_VERSION}/kops-linux-amd64 \
    && mv kops-linux-amd64 /usr/local/bin/kops \
    && chmod +x /usr/local/bin/kops

# Install helm
ENV HELM_VERSION 2.1.3
RUN curl -sSL -O http://storage.googleapis.com/kubernetes-helm/helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && tar -zxf helm-v${HELM_VERSION}-linux-amd64.tar.gz \
    && mv linux-amd64/helm /usr/local/bin/helm \
    && rm -rf linux-amd64 \
    && chmod +x /usr/local/bin/helm

# Install aws cli
RUN curl -sSL -O https://s3.amazonaws.com/aws-cli/awscli-bundle.zip \
    && unzip awscli-bundle.zip \
    && ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws \
    && rm awscli-bundle.zip \
    && rm -rf awscli-bundle

ENV BOOTSTRAP=true
ENV HOME=/geodesic
ENV KOPS_STATE_PATH=/geodesic/state/kops
ENV KUBECONFIG=/geodesic/state/kubernetes/kubeconfig
ENV AWS_DATA_PATH=/geodesic/state/aws/
ENV AWS_SHARED_CREDENTIALS_FILE=/geodesic/state/aws/credentials
ENV AWS_CONFIG_FILE=/geodesic/state/aws/config
ENV TF_STATE_FILE=/geodesic/state/terraform/terraform.tfstate
ENV HELM_HOME=/geodesic/state/helm/
ENV HISTFILE=/geodesic/state/history
ENV CLOUD_STATE_PATH=/geodesic/state
ENV CLOUD_CONFIG=/geodesic/state/env
ENV GEODESIC_PATH=/geodesic
ENV HELM_VALUES_PATH=/geodesic/state/helm/values
ENV XDG_CONFIG_HOME=/geodesic/state

VOLUME ["/geodesic/state"]

ADD dist /geodesic
ADD aws-assumed-role/profile /usr/local/bin/profile
ADD cloud /usr/local/bin/cloud
ADD confirm /usr/local/bin/confirm
ADD watch /usr/local/bin/watch

WORKDIR /geodesic

ENTRYPOINT ["/bin/bash", "--rcfile", "/geodesic/profile"]

