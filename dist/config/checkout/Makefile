DEFAULT_CONFIGS ?= https://geodesic.sh/default-configs.tar.gz

.PHONY : default
## Checkout default configs
default:
	@echo "# Downloading default configs"
	@curl -s $(DEFAULT_CONFIGS) | tar -zxvf --strip-components=1 - -C $(GEODESIC_STATE_PATH)

## Checkout cluster from S3
%:
	@[ ! -f ${CLOUD_CONFIG} ] || cloud config push
	@cloud config pull CLUSTER_STATE_BUCKET=config.$@

