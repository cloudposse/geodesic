ARG BANNER="niki geodesic"
ARG KUBERNETES_VERSION=1.9.6
ARG KOPS_VERSION=1.9.0

# other args than can be overridien are
#ARG AWS_VAULT_VERSION=4.2.0
#ARG PACKER_VERSION
#ARG ANSIBLE_VERSION
#ARG GCLOUD_SDK_VERSION
#ARG AWSEBCLI_VERSION
#ARG AWSCLI_VERSION
#--------------------------------------

FROM nikiai/geodesic

ARG AWLESS_VERSION=0.1.10
RUN curl --fail -SL -O https://github.com/wallix/awless/releases/download/${AWLESS_VERSION}/awless-linux-amd64.tar.gz \
    && tar -xzf awless-linux-amd64.tar.gz \
    && rm awless-linux-amd64.tar.gz \
    && mv awless /usr/local/bin
RUN apk add --no-cache py2-lxml
RUN pip install aws-google-auth