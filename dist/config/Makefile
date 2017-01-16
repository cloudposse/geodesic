include ../Makefile.helpers
-include Makefile.*

CLOUD_CONFIG_SAMPLE ?= $(GEODESIC_PATH)/config/env.sample

## Initialize environment
deps:
	@[ -f $(CLOUD_STATE_PATH)/env ] || cp -a $(CLOUD_CONFIG_SAMPLE) $(CLOUD_STATE_PATH)/env

## Edit configuration
edit: deps
	@vim $(CLOUD_CONFIG)

## View current configuration
view:
	@cat "$(CLOUD_CONFIG)"

## Validate configuration
validate:
	$(call assert-set,AWS_PROFILE)
	$(call assert-set,AWS_DEFAULT_PROFILE)
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

## Push state to S3
push: validate
	@git -C ${CLOUD_STATE_PATH} commit -a --message "Backup `date`"
	@aws s3 sync ${CLOUD_STATE_PATH} s3://$(CLUSTER_STATE_BUCKET)/state/ \
      --region $(CLUSTER_STATE_BUCKET_REGION) \
      --exclude ".git/*" \
      --exclude "*.swp" \
      --exclude "aws/*" \
      --exclude "history" \
      --no-follow-symlinks \
      --delete \
      --acl private

## Pull state from S3
pull: validate
	@aws s3 sync s3://$(CLUSTER_STATE_BUCKET)/state/ $(CLOUD_STATE_PATH) \
      --region ${CLUSTER_STATE_BUCKET_REGION} \
      --exclude ".git/*" \
      --exclude "*.swp" \
      --exclude "aws/*" \
      --exclude "history" \
      --no-follow-symlinks \
      --exact-timestamps \
      --delete


