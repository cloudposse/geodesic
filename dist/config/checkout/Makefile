## Checkout cluster from S3
%:
	@[ ! -f ${CLOUD_CONFIG} ] || cloud config push
	@cloud config pull CLUSTER_STATE_BUCKET=config.$@

