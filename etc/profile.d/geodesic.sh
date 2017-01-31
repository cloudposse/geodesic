#!/bin/bash
export GEODESIC_SHELL=true

echo "Entering the geodesic shell..."

# Setup some default envs
CLUSTER_STATE_BUCKET_REGION=${CLUSTER_STATE_BUCKET_REGION:-us-west-2}

cloud config init

if [ ! -d "${HELM_HOME}" ]; then
  cloud helm init-client
  cloud helm init-repos
fi

if [ -z "${SSH_AUTH_SOCK}" ]; then
  eval $(ssh-agent)
fi

[ -f "${KOPS_STATE_PATH}/id_rsa" ] && cloud kops add-ssh-key

