CLOUD_CONFIG_SAMPLE ?= $(GEODESIC_PATH)/modules/config/env.sample
MOUNT_PATH ?= /s3

include helpers
include all

## Checkout an existing cluster
checkout: module

## Initialize environment
init: init-git
	@[ -f $(CLOUD_STATE_PATH)/env ] || cp -a $(CLOUD_CONFIG_SAMPLE) $(CLOUD_STATE_PATH)/env
	@mkdir -p $(dir $(TF_STATE_FILE))
	@mkdir -p $(dir $(KUBECONFIG))
	@mkdir -p $(dir $(AWS_SHARED_CREDENTIALS_FILE))
	@mkdir -p $(dir $(AWS_CONFIG_FILE))
	@mkdir -p $(KOPS_STATE_PATH)
	@mkdir -p $(AWS_DATA_PATH)
	@mkdir -p $(CLOUD_STATE_PATH)/ssh
# Workaround for aws-cli which does not respect AWS_DATA_PATH
	@ln -sf ${AWS_DATA_PATH} ${HOME}/.aws

## Initialize local git repo
init-git:
	@if [ ! -f "${XDG_CONFIG_HOME}/git/config" ]; then \
		mkdir -p "${XDG_CONFIG_HOME}/git"; \
		touch "${XDG_CONFIG_HOME}/git/config"; \
		git config --global user.email ops@cloudposse.com; \
		git config --global user.name geodesic; \
	fi
	@if [ ! -d ${CLOUD_STATE_PATH}/.git ]; then \
		git -C ${CLOUD_STATE_PATH} init; \
		echo "aws/*" > ${CLOUD_STATE_PATH}/.gitignore; \
		echo "history" >> ${CLOUD_STATE_PATH}/.gitignore; \
		git -C  ${CLOUD_STATE_PATH} add .; \
	fi


## Edit configuration
edit: init
	@configure-env $(CLOUD_CONFIG)

## Reset local state
reset:
	@find $(CLOUD_STATE_PATH) -type d '!' -path '*/aws' -mindepth 1 -maxdepth 1  -exec rm -rf {} \;
	@rm -f $(CLOUD_STATE_PATH)/env $(CLOUD_STATE_PATH)/history $(CLOUD_STATE_PATH)/.bootstrapped
	@cloud config init
	@echo "Reset local state"

## View current configuration
view:
	@cat "$(CLOUD_CONFIG)"

## Validate configuration
validate: require-aws-profile
	$(call assert-set,CLUSTER_STATE_BUCKET)
	$(call assert-set,CLUSTER_STATE_BUCKET_REGION)

## Create state bucket
create-bucket: validate
	@aws s3 mb s3://$(CLUSTER_STATE_BUCKET) --region=$(CLUSTER_STATE_BUCKET_REGION)
	@aws s3api put-bucket-versioning \
		--bucket $(CLUSTER_STATE_BUCKET) \
		--region=$(CLUSTER_STATE_BUCKET_REGION) \
		--versioning-configuration Status=Enabled

## List bucket versions
list-bucket-versions:
	@aws s3api list-object-versions \
		--bucket $(CLUSTER_STATE_BUCKET) \
		--region $(CLUSTER_STATE_BUCKET_REGION) | \
			jq -M '{Objects: [.["Versions","DeleteMarkers"][] | {Key:.Key, VersionId : .VersionId}], Quiet: true}'

## Destroy state bucket
destroy-bucket: validate
	@echo -e "Destroying s3://$(CLUSTER_STATE_BUCKET)"
	@aws s3 rm s3://$(CLUSTER_STATE_BUCKET)/ --recursive --region=$(CLUSTER_STATE_BUCKET_REGION)
	@BUCKET_VERSIONS=`make list-bucket-versions`; \
	if [ -n "$$BUCKET_VERSIONS" ]; then \
		aws s3api delete-objects \
			--bucket $(CLUSTER_STATE_BUCKET) \
			--region $(CLUSTER_STATE_BUCKET_REGION) \
			--delete "$$BUCKET_VERSIONS"; \
	fi
	@aws s3 rb s3://$(CLUSTER_STATE_BUCKET) \
		--region $(CLUSTER_STATE_BUCKET_REGION) \
		--force

mount: validate 
	@mkdir -p $(MOUNT_PATH)
	@jq '.Credentials' < $(AWS_DATA_PATH)/cli/cache/$(AWS_DEFAULT_PROFILE)--*.json > $(AWS_DATA_PATH)/cli/cache/$(AWS_DEFAULT_PROFILE).json
	@/usr/bin/s3fs $(CLUSTER_STATE_BUCKET) $(MOUNT_PATH) \
		-o iam_role=$(AWS_DEFAULT_PROFILE).json,nosuid,nonempty,nodev,allow_other,default_acl=private,retries=5,use_cache=/var/tmp/
	@sleep 1
	@grep -q s3fs /etc/mtab || (echo "Failed to mount $(CLUSTER_STATE_BUCKET)"; exit 1)
	@echo "Mounted $(CLUSTER_STATE_BUCKET) to $(MOUNT_PATH)"

unmount:
	@/bin/umount $(MOUNT_PATH)
	@rmdir $(MOUNT_PATH)
	@echo "Unmounted $(CLUSTER_STATE_BUCKET)"

## Show what configurations have been modified
status:
	@git -C ${CLOUD_STATE_PATH} status

