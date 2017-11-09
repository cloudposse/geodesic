FROM cloudposse/geodesic:0.5.0

ENV DOCKER_IMAGE org/geodesic.example.org
ENV DOCKER_TAG latest

# Default AWS Profile name
ENV AWS_DEFAULT_PROFILE=ops

# Prefix of the cluster
ENV CLUSTER_PREFIX=aws

# Parent zone for the cluster
ENV CLUSTER_DNS_ZONE=example.com

# AWS Region for the cluster
ENV AWS_REGION=us-west-2

# AWS Region of the S3 bucket to store cluster configuration
ENV CLUSTER_STATE_BUCKET_REGION=us-west-2

# Username for connecting to the cluster via SSH
ENV SSH_USERNAME=admin

# Install kops
ENV KOPS_STATE_STORE s3://undefined
ENV KOPS_STATE_STORE_REGION us-east-1

# https://github.com/kubernetes/kops/blob/master/channels/stable
# https://github.com/kubernetes/kops/blob/master/docs/images.md
ENV KOPS_BASE_IMAGE=kope.io/k8s-1.7-debian-jessie-amd64-hvm-ebs-2017-07-28
ENV KOPS_DNS_ZONE "${CLUSTER_DNS_ZONE}"
ENV KOPS_BASTION_PUBLIC_NAME="bastion"
ENV KOPS_PRIVATE_SUBNETS="172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19"
ENV KOPS_UTILITY_SUBNETS="172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22"

# Instance sizes
ENV BASTION_MACHINE_TYPE "t2.medium"

# Kubernetes Master EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV MASTER_MACHINE_TYPE "t2.medium"

# Kubernetes Node EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV NODE_MACHINE_TYPE "t2.medium"

# Kubernetes node count (Node EC2 instance count) (optional, required if the cluster uses Kubernetes)
ENV NODE_MAX_SIZE 2
ENV NODE_MIN_SIZE 2


# Place configuration in 'conf/' directory
COPY conf/ /conf/

WORKDIR /conf/

RUN build-kops-manifest
