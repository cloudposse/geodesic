if [ -n "${CLUSTER_PREFIX}" ] && [ -n "${CLUSTER_DNS_ZONE}" ]; then
  CLUSTER_NAME=${CLUSTER_PREFIX}.${CLUSTER_DNS_ZONE}  # Full name of cluster
  CLUSTER_STATE_BUCKET=config.${CLUSTER_NAME}         # Bucket to store cluster state
  KOPS_STATE_STORE=s3://${CLUSTER_STATE_BUCKET}       # S3 bucket to store cluster state for kops
fi

if [ -z "${CLUSTER_STATE_BUCKET_REGION}" ]; then
  CLUSTER_STATE_BUCKET_REGION=us-east-1               # Primary region of bucket
fi

if [ -z "${SSH_USERNAME}" ]; then
  SSH_USERNAME=admin                                  # Username to use for connecting to cluster
fi
