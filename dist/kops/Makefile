include Makefile.*

deps: 
	@aws s3 mb $(KOPS_STATE)

export:
	$(KOPS_BIN) export kubecfg \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

update:
	@$(KOPS_BIN) update cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

up:
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
      --kubernetes-version=$(KOPS_KUBERNETES_VERSION) \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

tf:
	@$(KOPS_BIN) update cluster \
      --out=terraform/ \
      --target=terraform \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

down:
	@$(KOPS_BIN) delete cluster \
      --name=$(KOPS_NAME) \
      --state=$(KOPS_STATE) \
      --yes

ssh:
	@ssh admin@api.$(KOPS_NAME) || true
