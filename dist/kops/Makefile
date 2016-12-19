include ../Makefile.helpers
include Makefile.*

## Resolve dependencies
deps: create-bucket


## Export kubeconfig
export: validate
	$(KOPS_BIN) export kubecfg \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Apply pending changes to the cluster
update: validate
	@$(KOPS_BIN) update cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

validate:
	$(call assert-set,AWS_PROFILE)
	$(call assert-set,AWS_DEFAULT_PROFILE)
	$(call assert-set,KOPS_NAME)
	$(call assert-set,KOPS_ZONES)
	$(call assert-set,KOPS_DNS_ZONE)
	$(call assert-set,KOPS_ASSOCIATE_PUBLIC_IP)
	$(call assert-set,KOPS_ADMIN_ACCESS)
	$(call assert-set,KOPS_NODE_COUNT)
	$(call assert-set,KOPS_NODE_SIZE)
	$(call assert-set,KOPS_MASTER_SIZE)
	$(call assert-set,KOPS_MASTER_ZONES)
	$(call assert-set,KOPS_KUBERNETES_VERSION)
	$(call assert-set,KOPS_KOPS_STATE)

## Bring up a new cluster
up: deps validate
	@echo "Creating cluster $(KOPS_NAME)..."
	@$(KOPS_BIN) create cluster \
			--cloud=$(KOPS_CLOUD) \
			--zones=$(KOPS_ZONES) \
      --dns-zone=$(KOPS_DNS_ZONE) \
      --associate-public-ip=$(KOPS_ASSOCIATE_PUBLIC_IP) \
	    --admin-access=$(KOPS_ADMIN_ACCESS) \
      --node-count=$(KOPS_NODE_COUNT) \
      --node-size=$(KOPS_NODE_SIZE) \
      --master-size=$(KOPS_MASTER_SIZE) \
      --master-zones=$(KOPS_MASTER_ZONES) \
      --kubernetes-version=$(KUBERNETES_VERSION) \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

## Export terraform configuration
tf: validate
	@$(KOPS_BIN) update cluster \
      --out=terraform/ \
      --target=terraform \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Tear down an existing cluster
down: validate
	@$(KOPS_BIN) delete cluster \
      --name=$(KOPS_NAME) \
      --state=$(KOPS_STATE) \
      --yes

## Connect to the cluster using SSH
ssh: validate
	@ssh admin@api.$(KOPS_NAME) || true
