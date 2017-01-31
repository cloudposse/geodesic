if [ -n "${CLUSTER_PREFIX}" ] && [ -n "${CLUSTER_DNS_ZONE}" ]; then
  export CLUSTER_NAME=${CLUSTER_PREFIX}.${CLUSTER_DNS_ZONE}  # Full name of cluster
  export CLUSTER_STATE_BUCKET=config.${CLUSTER_NAME}         # Bucket to store cluster state
  export KOPS_STATE_STORE=s3://${CLUSTER_STATE_BUCKET}       # S3 bucket to store cluster state for kops
fi

if [ -z "${CLUSTER_STATE_BUCKET_REGION}" ]; then
  export CLUSTER_STATE_BUCKET_REGION=us-east-1               # Primary region of bucket
fi

if [ -z "${SSH_USERNAME}" ]; then
  export SSH_USERNAME=admin                                  # Username to use for connecting to cluster
fi
