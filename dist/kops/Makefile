include ../Makefile.helpers
include Makefile.*

## Resolve dependencies
deps: 
	@aws s3 mb $(KOPS_STATE)

## Export kubeconfig
export:
	$(KOPS_BIN) export kubecfg \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Apply pending changes to the cluster
update:
	@$(KOPS_BIN) update cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

## Bring up a new cluster
up: deps
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
tf:
	@$(KOPS_BIN) update cluster \
      --out=terraform/ \
      --target=terraform \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Tear down an existing cluster
down:
	@$(KOPS_BIN) delete cluster \
      --name=$(KOPS_NAME) \
      --state=$(KOPS_STATE) \
      --yes

## Connect to the cluster using SSH
ssh:
	@ssh admin@api.$(KOPS_NAME) || true
