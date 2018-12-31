FROM {{ getenv "GEODESIC_IMAGE" "cloudposse/geodesic" }}:{{ getenv "GEODESIC_TAG" "latest" }}

ENV DOCKER_IMAGE "{{ getenv "DOCKER_IMAGE" "org/geodesic.example.org" }}"
ENV DOCKER_TAG "{{ getenv "DOCKER_TAG" "latest" }}"

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE="{{ getenv "AWS_DEFAULT_PROFILE" "ops" }}"

# AWS Region for the cluster
ENV AWS_REGION="{{ getenv "AWS_REGION" "us-west-2"}}"

# Install kops
ENV KOPS_STATE_STORE "{{ getenv "KOPS_STATE_STORE" "s3://undefined" }}"
ENV KOPS_STATE_STORE_REGION "{{ getenv "KOPS_STATE_STORE_REGION" "us-east-1" }}"

# https://github.com/kubernetes/kops/blob/master/channels/stable
# https://github.com/kubernetes/kops/blob/master/docs/images.md
ENV KOPS_BASE_IMAGE="{{ getenv "KOPS_BASE_IMAGE" "kope.io/k8s-1.10-debian-jessie-amd64-hvm-ebs-2018-08-17" }}"
ENV KOPS_DNS_ZONE "{{ getenv "KOPS_DNS_ZONE" "kops.example.com" }}"
ENV KOPS_BASTION_PUBLIC_NAME="{{ getenv "KOPS_BASTION_PUBLIC_NAME" "bastion" }}"
ENV KOPS_PRIVATE_SUBNETS="{{ getenv "KOPS_PRIVATE_SUBNETS" "172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19" }}"
ENV KOPS_UTILITY_SUBNETS="{{ getenv "KOPS_UTILITY_SUBNETS" "172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22" }}"

# Instance sizes
ENV BASTION_MACHINE_TYPE "{{ getenv "BASTION_MACHINE_TYPE" "t2.medium" }}"

# Kubernetes Master EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV MASTER_MACHINE_TYPE "{{ getenv "MASTER_MACHINE_TYPE" "t2.medium" }}"

# Kubernetes Node EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV NODE_MACHINE_TYPE "{{ getenv "NODE_MACHINE_TYPE" "t2.medium" }}"

# Kubernetes node count (Node EC2 instance count) (optional, required if the cluster uses Kubernetes)
ENV NODE_MAX_SIZE "{{ getenv "NODE_MAX_SIZE" "2" }}"
ENV NODE_MIN_SIZE "{{ getenv "NODE_MIN_SIZE" "2" }}"

# Terraform
ENV TF_BUCKET ""
ENV TF_BUCKET_REGION "us-east-1"
ENV TF_DYNAMODB_TABLE ""

# Place configuration in 'conf/' directory
COPY conf/ /conf/

WORKDIR /conf/

RUN build-kops-manifest
