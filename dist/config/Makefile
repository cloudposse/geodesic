include ../Makefile.helpers
-include Makefile.*

## Edit configuration
edit:
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
	@aws s3 mb $(CLUSTER_STATE_BUCKET) --region=$(CLUSTER_STATE_BUCKET_REGION)
	@aws s3api put-bucket-versioning \
    --bucket $(CLUSTER_STATE_BUCKET) \
    --region=$(CLUSTER_STATE_BUCKET_REGION) \
    --versioning-configuration Status=Enabled

## Destroy state bucket
destroy-bucket: validate
	@echo -e "Destroying s3://$(CLUSTER_STATE_BUCKET)"
	@aws s3 rm s3://$(CLUSTER_STATE_BUCKET)/ --recursive --region=us-east-1
	@aws s3api delete-objects \
    --bucket $(CLUSTER_STATE_BUCKET) \
    --region $(CLUSTER_STATE_BUCKET_REGION) \
    --delete "`aws s3api list-object-versions \
                 --bucket $(CLUSTER_STATE_BUCKET_REGION) \
                 --region $(CLUSTER_STATE_BUCKET_REGION) | \
               jq -M '{Objects: [.["Versions","DeleteMarkers"][] | {Key:.Key, VersionId : .VersionId}], Quiet: true}'`"
	@aws s3 rb s3://$(CLUSTER_STATE_BUCKET) \
    --region $(CLUSTER_STATE_BUCKET_REGION) \
    --force

## Push state to S3
push: validate
	@aws s3 sync ${TF_VAR_state_dir} s3://$(CLUSTER_STATE_BUCKET)/state/ \
      --region $(CLUSTER_STATE_BUCKET_REGION) \
      --exclude ".git/*" \
      --exclude "*.swp" \
      --no-follow-symlinks \
      --delete \
      --acl private

## Pull state from S3
pull: validate
	  aws s3 sync s3://$(CLUSTER_STATE_BUCKET)/state/ $(TF_VAR_state_dir) \
        --region ${CLUSTER_STATE_BUCKET_REGION} \
        --exclude ".git/*" \
        --exclude "*.out" \
        --no-follow-symlinks \
        --exact-timestamps \
        --delete


