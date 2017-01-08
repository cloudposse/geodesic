include ../Makefile.helpers
include Makefile.*

## Resolve dependencies
deps:
	@mkdir -p $(KOPS_STATE_PATH)

## Export kubeconfig
export: validate
	$(KOPS_BIN) export kubecfg \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Edit cluster configuration
edit: validate
	@$(KOPS_BIN) edit cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME)

## Upgrade cluster or apply configuration updates
upgrade: validate
	@$(KOPS_BIN) upgrade cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
	    --yes
	@cloud kops update

## Apply pending changes to the cluster
update: validate
	@$(KOPS_BIN) update cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

validate:
	$(call assert-set,AWS_PROFILE)
	$(call assert-set,AWS_DEFAULT_PROFILE)
	$(call assert-set,KUBERNETES_VERSION)
	$(call assert-set,KOPS_NAME)
	$(call assert-set,KOPS_ZONES)
	$(call assert-set,KOPS_DNS_ZONE)
	$(call assert-set,KOPS_ASSOCIATE_PUBLIC_IP)
	$(call assert-set,KOPS_ADMIN_ACCESS)
	$(call assert-set,KOPS_NODE_COUNT)
	$(call assert-set,KOPS_NODE_SIZE)
	$(call assert-set,KOPS_MASTER_SIZE)
	$(call assert-set,KOPS_MASTER_ZONES)
	$(call assert-set,KOPS_STATE)

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
      --ssh-public-key=$(KOPS_SSH_PUBLIC_KEY) \
      --yes

## Wait until cluster online
wait-until-ready: validate
	@echo -n "Waiting until $(KOPS_DNS_ZONE) online"
	@until kubectl api-versions 2>/dev/null; do \
    echo -n .; \
    sleep 1;\
  done
	@echo

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

## Delete SSH key pair for this deployment
delete-ssh-key: validate
	@rm -f "$(KOPS_SSH_PRIVATE_KEY)" "$(KOPS_SSH_PUBLIC_KEY)"

## Create a unique SSH key for this deployment
create-ssh-key: deps validate 
	@if [ -f "$(KOPS_SSH_PRIVATE_KEY)" ]; then \
    echo "SSH key $(KOPS_SSH_PRIVATE_KEY) already exists"; \
  else \
		ssh-keygen -t rsa -N '' -b 8192 -C "$(KOPS_NAME)"  -f "$(KOPS_SSH_PRIVATE_KEY)"; \
    rm -f "$(KOPS_SSH_PUBLIC_KEY)"; \
	fi
	@if [ -f "$(KOPS_SSH_PUBLIC_KEY)" ]; then \
	  echo "SSH pub key $(KOPS_SSH_PUBLIC_KEY) already exists"; \
	else \
	  ssh-keygen -y -f "$(KOPS_SSH_PRIVATE_KEY)" | tr -d "\n" > "$(KOPS_SSH_PUBLIC_KEY)" ; \
	fi
# Ensure perms are always correct
	@chmod 600 "$(KOPS_SSH_PRIVATE_KEY)"

## Rotate SSH key for deployment
rotate-ssh-key: delete-ssh-key create-ssh-key configure-ssh-key

## Upload SSH key to deployment
configure-ssh-key: validate
	@echo "Configuring public ssh key"
	@kops create secret sshpublickey admin -i $(KOPS_SSH_PUBLIC_KEY) \
      --name=$(KOPS_NAME) \
      --state=$(KOPS_STATE) 

## Connect to the cluster using SSH
ssh-as-admin: validate
	@ssh -i $(KOPS_SSH_PRIVATE_KEY) admin@api.$(KOPS_NAME) || true

ssh:
	$(call assert-set,GITHUB_USERNAME)
	$(call assert-set,KOPS_NAME)
	@ssh $(GITHUB_USERNAME)@api.$(KOPS_NAME) || true
