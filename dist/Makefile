include Makefile.*

## Setup environment
deps:
	@cloud config create-bucket

## Bring up a new cluster
up:
	make -C kops $@

## Tear down an existing cluster
down:
	make -C kops $@

## Connect to the cluster via SSH
ssh:
	make -C kops $@

.PHONY: config
## Manage configuration
config: 
	@make -C $@

## Configure cloud
configure:
	@cloud config edit

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
