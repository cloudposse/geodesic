FROM nikiai/geodesic

# the args below are just to showcase what feature of geodesic can be modified with on-build image, these have effect only if passed as aws-args
ARG BANNER="niki geodesic"

ARG SOPS_VERSION=3.0.2
ARG HELM_VERSION=2.8.2
ARG AWS_VAULT_VERSION=4.2.0

# above arguements can be build as a default value is already there

#ARG PACKER_VERSION
#ARG ANSIBLE_VERSION
#ARG GCLOUD_SDK_VERSION
#ARG AWSEBCLI_VERSION

ARG AWSCLI_VERSION
#1.11.185
ARG KUBERNETES_VERSION
#1.9.6
ARG KOPS_VERSION
#1.9.0
ENV AWLESS_VERSION 0.1.10
RUN curl --fail -SL -O https://github.com/wallix/awless/releases/download/v0.1.10/awless-linux-amd64.tar.gz \
    && tar -xzf awless-linux-amd64.tar.gz \
    && rm awless-linux-amd64.tar.gz \
    && mv awless /usr/local/bin
RUN apk add --no-cache py2-lxml
RUN pip install aws-google-auth
#docker build --rm --build-arg KUBERNETES_VERSION=1.9.6 --build-arg KOPS_VERSION=1.9.0 --build-arg AWS_VAULT_VERSION="" -t nikiai/tools .