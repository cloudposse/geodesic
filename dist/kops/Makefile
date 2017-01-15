include ../Makefile.helpers
include Makefile.*

## Resolve dependencies
deps:
	@mkdir -p $(KOPS_STATE_STORE_PATH)

## Export kubeconfig
export-kubecfg: validate
	$(KOPS_BIN) export kubecfg

## Export kops configuration
backup-config: validate deps
	@echo "Writing configuration to $(KOPS_STATE_STORE_PATH)/kops.yaml"
	@$(KOPS_BIN) get cluster -o yaml --full > $(KOPS_STATE_STORE_PATH)/kops.yaml

## Edit cluster configuration
edit: validate
	@$(KOPS_BIN) edit cluster

## Upgrade cluster or apply configuration updates
upgrade: validate 
	@$(KOPS_BIN) upgrade cluster \
	    --yes
	@cloud kops apply

## Apply pending changes to the cluster's autoscaling group configuration (does not modify running instances)
update: validate
	@$(KOPS_BIN) update cluster \
	  --yes

## Rolling rebuild of all instances
rolling-update: validate
	@$(KOPS_BIN) rolling-update cluster \
	  --yes

## Show pending changes
plan: validate
	@$(KOPS_BIN) rolling-update cluster

## Update configuration and perform a rolling-update of all instances
apply: update rolling-update
	@cloud config push

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
	$(call assert-set,KOPS_STATE_STORE)
	$(call assert-set,KOPS_STATE_STORE_PATH)
	$(call assert-set,KOPS_CONFIG)

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
			--name=$(KOPS_NAME) \
			--ssh-public-key=$(KOPS_SSH_PUBLIC_KEY) \
			--yes

## Wait until cluster online
wait-until-ready: validate
	@echo -n "Waiting until $(KOPS_NAME) online"
	@until kubectl api-versions 2>/dev/null; do \
	  echo -n .; \
	  sleep 1;\
	  done
	@echo

## Export terraform configuration
tf: validate
	@$(KOPS_BIN) update cluster \
	  --out=terraform/ \
	  --target=terraform

## Tear down an existing cluster
down: validate
	@$(KOPS_BIN) delete cluster \
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
rotate-ssh-key: delete-ssh-key create-ssh-key configure-ssh-key apply wait-until-ready

## List secrets
describe-secrets:
	@kops describe secrets

## Upload SSH key to deployment
configure-ssh-key: validate
	@echo "Configuring public ssh key"
	@kops delete secret sshpublickey admin || true
	@kops create secret sshpublickey admin --pubkey=$(KOPS_SSH_PUBLIC_KEY)

## Connect to the cluster using SSH
ssh-as-admin: validate
	@ssh -i $(KOPS_SSH_PRIVATE_KEY) admin@api.$(KOPS_NAME) || true

ssh:
	$(call assert-set,GITHUB_USERNAME)
	$(call assert-set,KOPS_NAME)
	@ssh $(GITHUB_USERNAME)@api.$(KOPS_NAME) || true
