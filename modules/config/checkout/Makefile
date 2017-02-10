DEFAULT_CONFIGS ?= https://geodesic.sh/default-configs.tar.gz

## Checkout cluster from S3
%:
	@cloud config pull CLUSTER_STATE_BUCKET=config.$@
	@cloud kops add-ssh-key

