# Setup some default envs
export LESS=-Xr

if [ -n "${CLUSTER_PREFIX}" ] && [ -n "${CLUSTER_DNS_ZONE}" ]; then
  export CLUSTER_NAME=${CLUSTER_PREFIX}.${CLUSTER_DNS_ZONE}  # Full name of cluster
  export CLUSTER_STATE_BUCKET=config.${CLUSTER_NAME}         # Bucket to store cluster state
  export KOPS_STATE_STORE=s3://${CLUSTER_STATE_BUCKET}       # S3 bucket to store cluster state for kops
  export CLUSTER_REPO_PATH=${LOCAL_STATE}/clusters/${CLUSTER_NAME}
else
  unset CLUSTER_NAME
  unset CLUSTER_STATE_BUCKET
  unset KOPS_STATE_STORE
  unset CLUSTER_REPO_PATH
fi

if [ -z "${CLUSTER_STATE_BUCKET_REGION}" ]; then
  export CLUSTER_STATE_BUCKET_REGION=us-east-1               # Primary region of bucket
fi


#
# SSH
#
if [ -z "${SSH_USERNAME}" ]; then
  export SSH_USERNAME=admin                                  # Username to use for connecting to cluster
fi


#
# Helm
#
export HELM_HOME=${REMOTE_STATE}/helm/
export HELM_VALUES_PATH=${REMOTE_STATE}/helm/values

#
# AWS
#
export AWS_DATA_PATH=${LOCAL_STATE}/aws/
export AWS_SHARED_CREDENTIALS_FILE=${LOCAL_STATE}/aws/credentials
export AWS_CONFIG_FILE=${LOCAL_STATE}/aws/config

#
# Shell
#

export HISTFILE=${LOCAL_STATE}/history
export SHELL=/bin/bash

#
# Git
#
export XDG_CONFIG_HOME=${LOCAL_STATE}

#
# Kops
#
export KOPS_STATE_PATH=${REMOTE_STATE}/kops

#
# Kubernetes
#
export KUBECONFIG=${REMOTE_STATE}/kubernetes/kubeconfig


#
# Terraform
#
export TF_STATE_DIR=${LOCAL_STATE}/terraform/${CLUSTER_NAME}
export TF_STATE_FILE=${TF_STATE_DIR}/terraform.tfstate
export TF_LOG=ERROR
export TF_LOG_PATH=${TF_STATE_DIR}/terraform.log
export TF_BUCKET=${CLUSTER_STATE_BUCKET}
export TF_BUCKET_PREFIX=geodesic/terraform

#
# Geodesic
#
export CLOUD_CONFIG=${REMOTE_STATE}/env
export CLOUD_CONFIG_SAMPLE=${GEODESIC_PATH}/config/env.sample
export SHELL_NAME=Geodesic

