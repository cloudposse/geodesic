include helpers
include all

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

## Reset local state
reset: require-cluster-mounted
	@rm -rf $(REMOTE_STATE)/* $(REMOTE_STATE)/.bootstrapped
	@rm -f $(LOCAL_STATE)/history
	@cloud config init
	@echo "Reset local state"

## Validate configuration
validate: require-aws-profile
	$(call assert-set,CLUSTER_STATE_BUCKET)
	$(call assert-set,CLUSTER_STATE_BUCKET_REGION)

## Create state bucket
create-bucket: validate require-bucket-does-not-exist
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
	@(nohup goofys -f --file-mode=0600 --region ${CLUSTER_STATE_BUCKET_REGION} --sse $(CLUSTER_STATE_BUCKET) ${REMOTE_MOUNT_POINT}) 2>&1 >>/var/log/goofys.log 2>&1 &
	@until mountpoint -q ${REMOTE_MOUNT_POINT}; do sleep 0.250; done
	@echo "Mounted $(CLUSTER_STATE_BUCKET) to $(REMOTE_MOUNT_POINT)"
	@mkdir -p $(REMOTE_STATE)
	@mkdir -p $(dir $(KUBECONFIG))
	@mkdir -p $(KOPS_STATE_PATH)
	@mkdir -p $(HELM_VALUES_PATH)
	@[ ! -f "${KOPS_STATE_PATH}/id_rsa" ] || cloud kops add-ssh-key

## Unmount remote cluster state bucket
unmount:
	@[ -d $(REMOTE_MOUNT_POINT) ] || (echo "Mount point does not exist"; exit 1)
	@mountpoint -q $(REMOTE_MOUNT_POINT) || (echo "Nothing mounted to mount point"; exit 1)
	/bin/umount -f $(REMOTE_MOUNT_POINT)
	@rmdir $(REMOTE_MOUNT_POINT)
	@echo "Unmounted $(CLUSTER_STATE_BUCKET)"

## Show what configurations have been modified
status:
	@git -C ${LOCAL_STATE} status

require-bucket-does-not-exist:
	@aws s3 ls s3://$(CLUSTER_STATE_BUCKET) --region $(CLUSTER_STATE_BUCKET_REGION) >/dev/null 2>&1; \
	if [ $$? -eq 0 ]; then \
		echo "Bucket $(CLUSTER_STATE_BUCKET) already exists"; \
		exit 1; \
	else \
		exit 0; \
	fi
