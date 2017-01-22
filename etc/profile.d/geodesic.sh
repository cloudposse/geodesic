#!/bin/bash
export GEODESIC_SHELL=true

echo "Entering the geodesic shell..."

# Setup some default envs
CLUSTER_STATE_BUCKET_REGION=${CLUSTER_STATE_BUCKET_REGION:-us-west-2}

# Create directories
mkdir -p $(dirname ${TF_STATE_FILE})
mkdir -p $(dirname ${KUBECONFIG})
mkdir -p $(dirname ${AWS_SHARED_CREDENTIALS_FILE})
mkdir -p $(dirname ${AWS_CONFIG_FILE})
mkdir -p ${KOPS_STATE_PATH}
mkdir -p ${AWS_DATA_PATH}
mkdir -p ${CLOUD_STATE_PATH}/ssh

if [ ! -d "${HELM_HOME}" ]; then
  cloud helm init-client
  cloud helm init-repos
fi

# Workaround for aws-cli which does not respect AWS_DATA_PATH
ln -sf ${AWS_DATA_PATH} ${HOME}/.aws

if [ -z "${SSH_AUTH_SOCK}" ]; then
  eval $(ssh-agent)
  if [ -f "${KOPS_STATE_PATH}/id_rsa" ]; then
    chmod 600 "${KOPS_STATE_PATH}/id_rsa"
  fi 
fi

cloud kops add-ssh-key

