ARG BANNER="niki.ai"
ARG KUBERNETES_VERSION=1.9.6
ARG KOPS_VERSION=1.9.0
ARG AWS_VAULT_VERSION=""
# other args than can be overridien are
#ARG AWS_VAULT_VERSION=4.2.0
#ARG PACKER_VERSION
#ARG ANSIBLE_VERSION
#ARG GCLOUD_SDK_VERSION
#ARG AWSEBCLI_VERSION
#ARG AWSCLI_VERSION
#--------------------------------------

FROM nikiai/geodesic

ENV AWLESS_VERSION "v0.1.10"
RUN curl --fail -SL -O https://github.com/wallix/awless/releases/download/${AWLESS_VERSION}/awless-linux-amd64.tar.gz \
    && tar -xzf awless-linux-amd64.tar.gz \
    && rm awless-linux-amd64.tar.gz \
    && mv awless /usr/local/bin
RUN apk add --no-cache py2-lxml
ENV GOOGLE_SP_ID 313486584448
ENV GOOGLE_IDP_ID C01uo53i7
#ENV GOOGLE_USERNAME "rohit.verma@niki.ai"
RUN pip install aws-google-auth==0.0.24