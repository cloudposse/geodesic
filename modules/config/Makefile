CLOUD_CONFIG_SAMPLE ?= $(GEODESIC_PATH)/modules/config/env.sample

include ../Makefile.helpers
-include Makefile.*

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
	@rm -f $(CLOUD_STATE_PATH)/serial $(CLOUD_STATE_PATH)/env $(CLOUD_STATE_PATH)/history $(CLOUD_STATE_PATH)/.bootstrapped
	@cloud config init
	@echo "Reset local state"

## View current configuration
view:
	@cat "$(CLOUD_CONFIG)"

## Validate configuration
validate: require-aws-profile
	$(call assert-set,CLUSTER_STATE_BUCKET)
	$(call assert-set,CLUSTER_STATE_BUCKET_REGION)

## Initialize serial for optimistic-locking
init-serial: validate confirm
	@date +'%Y%m%d%H%M%S' > $(CLOUD_STATE_PATH)/serial
	@cat $(CLOUD_STATE_PATH)/serial
	@aws s3 cp $(CLOUD_STATE_PATH)/serial s3://$(CLUSTER_STATE_BUCKET)/state/serial --region=$(CLUSTER_STATE_BUCKET_REGION);

## Verify the local serial matches remote serial (that your configuration matches the remote)
verify-serial: validate
	@aws s3 cp s3://$(CLUSTER_STATE_BUCKET)/state/serial /tmp/serial --region=$(CLUSTER_STATE_BUCKET_REGION) >/dev/null;
	@REMOTE_SERIAL=`cat /tmp/serial`; \
	LOCAL_SERIAL=`cat $(CLOUD_STATE_PATH)/serial`; \
	if [ "$$REMOTE_SERIAL" == "$$LOCAL_SERIAL" ]; then \
	  echo "Serial up to date: $$LOCAL_SERIAL"; \
	  exit 0; \
	else \
	  echo "Remote Serial: $$REMOTE_SERIAL"; \
	  echo "Local Serial:  $$LOCAL_SERIAL"; \
	  exit 1; \
	fi

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

## Push state to S3
push: validate verify-serial
	@date +'%Y%m%d%H%M%S' > $(CLOUD_STATE_PATH)/serial
	@git -C ${CLOUD_STATE_PATH} add .
	@git -C ${CLOUD_STATE_PATH} commit -a --message "Backup `date`"
	@aws s3 sync ${CLOUD_STATE_PATH} s3://$(CLUSTER_STATE_BUCKET)/state/ \
		--region $(CLUSTER_STATE_BUCKET_REGION) \
		--exclude "*.swp" \
		--exclude "aws/*" \
		--exclude "history" \
		--no-follow-symlinks \
		--exact-timestamps \
		--delete \
		--acl private

## Pull state from S3
pull: validate
	@aws s3 sync s3://$(CLUSTER_STATE_BUCKET)/state/ $(CLOUD_STATE_PATH) \
		--region ${CLUSTER_STATE_BUCKET_REGION} \
		--exclude "*.swp" \
		--exclude "aws/*" \
		--exclude "history" \
		--no-follow-symlinks \
		--exact-timestamps \
		--delete


