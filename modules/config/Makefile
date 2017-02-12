CLOUD_CONFIG_SAMPLE ?= $(GEODESIC_PATH)/modules/config/env.sample

include helpers
include all

## Use an existing cluster
use: module

## Initialize environment
init: init-git
	@mkdir -p $(dir $(TF_STATE_FILE))
	@mkdir -p $(dir $(AWS_SHARED_CREDENTIALS_FILE))
	@mkdir -p $(dir $(AWS_CONFIG_FILE))
	@mkdir -p $(AWS_DATA_PATH)
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
	@if [ ! -d ${LOCAL_STATE}/.git ]; then \
		git -C ${LOCAL_STATE} init; \
		echo "aws/*" > ${LOCAL_STATE}/.gitignore; \
		echo "history" >> ${LOCAL_STATE}/.gitignore; \
		git -C  ${LOCAL_STATE} add .; \
	fi


## Edit configuration
edit: init require-cluster-mounted
	@configure-env $(CLOUD_CONFIG)

## Reset local state
reset: require-cluster-mounted
	@rf -rf $(REMOTE_STATE)/* $(REMOTE_STATE)/.bootstrapped
	@rm -f $(LOCAL_STATE)/history
	@cloud config init
	@echo "Reset local state"

## View current configuration
view: require-cluster-mounted
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

## Mount remote cluster state bucket
mount: validate 
	@mkdir -p $(REMOTE_MOUNT_POINT)
	@/usr/bin/s3fs $(CLUSTER_STATE_BUCKET) $(REMOTE_MOUNT_POINT) \
		-o iam_role=$(AWS_DEFAULT_PROFILE),nosuid,nonempty,nodev,allow_other,default_acl=private,retries=5,use_sse,use_cache=/var/tmp/
	@sleep 1
	@grep -q s3fs /etc/mtab || (echo "Failed to mount $(CLUSTER_STATE_BUCKET)"; rmdir $(REMOTE_MOUNT_POINT); exit 1)
	@echo "Mounted $(CLUSTER_STATE_BUCKET) to $(REMOTE_MOUNT_POINT)"
	@mkdir -p $(REMOTE_STATE)
	@[ -f $(REMOTE_STATE)/env ] || cp -a $(CLOUD_CONFIG_SAMPLE) $(REMOTE_STATE)/env
	@mkdir -p $(dir $(KUBECONFIG))
	@mkdir -p $(KOPS_STATE_PATH)

## Unmount remote cluster state bucket
unmount:
	@[ -d $(REMOTE_MOUNT_POINT) ] || (echo "Nothing mounted"; exit 1)
	@/bin/umount $(REMOTE_MOUNT_POINT)
	@rmdir $(REMOTE_MOUNT_POINT)
	@echo "Unmounted $(CLUSTER_STATE_BUCKET)"

## Show what configurations have been modified
status:
	@git -C ${LOCAL_STATE} status

