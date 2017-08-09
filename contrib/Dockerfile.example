FROM cloudposse/geodesic:0.2.0

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

# Kubernetes Master EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV KOPS_MASTER_SIZE=t2.medium

# Kubernetes Node EC2 instance type (optional, required if the cluster uses Kubernetes)
ENV KOPS_NODE_SIZE=t2.medium

# Kubernetes node count (Node EC2 instance count) (optional, required if the cluster uses Kubernetes)
ENV KOPS_NODE_COUNT=3

# Place configuration in 'conf/' directory
COPY conf/ /conf/

WORKDIR /conf/
