include Makefile.*

## Setup environment
deps:
	@cloud config create-bucket

## Bring up a new cluster
up:
	@make -C kops $@ wait-until-ready

## Tear down an existing cluster
down:
	@make -C kops $@

## Connect to the cluster via SSH
ssh:
	@make -C kops $@

.PHONY: config
## Manage configuration
config: 
	@make -C $@

## Configure cloud
configure:
	@cloud config edit

## Initialize the system
init:
	@[ ! -f $(GEODESIC_PATH)/state/.initialized ] || (echo "Cluster already initialized"; exit 1)
	@cloud kubernetes set-dockercfg        # Set the Docker Registry secret
	@cloud helm init                       # Initalize helm for packages
	@cloud distro install kube-system all  # Install essential k8s services
	@cloud distro install default all      # Install default namespace
	@cloud config push                     # Save the configuration
	@touch $(GEODESIC_PATH)/state/.initialized

.PHONY: deploy
## Deploy distributions
deploy: 
	@make -C $@

.PHONY: distro
## Manage the distribution
distro:
	@make -C $@

.PHONY: kops
## Manage kops
kops:
	@make -C $@

.PHONY: kubernetes
## Manage kubernetes
kubernetes:
	@make -C $@
  
.PHONY: helm
## Manage helm
helm:
	@make -C $@

.PHONY: terraform
## Manage terraform
terraform:
	@make -C $@
