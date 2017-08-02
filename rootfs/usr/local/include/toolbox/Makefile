include helpers
include all
include cluster

.PHONY : deps
## Setup environment
deps: require-aws-profile
	@cloud config create-bucket

## Initialize cluster
init:
	@cloud config init

## Create a new cluster
create: require-aws-profile
		@set -o allexport; \
		 source /etc/profile.d/defaults.sh && \
		 cloud config create-bucket && \
		 cloud config mount

#create: require-aws-profile
#		@set -o allexport; \
#		 CLOUD_CONFIG=/tmp/env; \
#		 ([ -f $$CLOUD_CONFIG ] || cp -a $(CLOUD_CONFIG_SAMPLE) $$CLOUD_CONFIG) && \
#		 configure-env $$CLOUD_CONFIG && \
#		 source $$CLOUD_CONFIG && \
#		 source /etc/profile.d/defaults.sh && \
#		 cloud config create-bucket && \
#		 cloud config mount && \
#		@mv -f /tmp/env $(CLOUD_CONFIG)

.PHONY : up
## Bring up a new cluster
up:
	@cloud kops $@ wait-for-kubernetes
	@cloud bootstrap

.PHONY : down
## Tear down an existing cluster
down:
	@cloud kops $@
	@rm -f $(REMOTE_STATE)/.bootstrapped

.PHONY : ssh
## Connect to the cluster via SSH
ssh:
	@cloud kops $@

.PHONY: config
## Manage configuration
config: module

## Configure cloud
.PHONY : configure
configure:
	@cloud config edit

.PHONY : bootstrap
## Bootstrap the overall system
bootstrap: require-aws-profile require-cluster-mounted require-cluster-online 
	@[ ! -f $(REMOTE_STATE)/.bootstrapped ] || (echo "Cluster already bootstraped"; exit 1)
	@[ -z "$(DOCKER_USER)" ] || [ -z "$(DOCKER_PASSWORD)" ] || [ -z "$(DOCKER_EMAIL)" ] || \
		cloud kubernetes create-dockercfg  # Set the Docker Registry secret
	@cloud helm init                       # Initalize helm for packages
	@cloud helm init-repos                 # Initalize helm for packages
	@cloud helm update                     # Update repo index
	@touch $(REMOTE_STATE)/.bootstrapped   # Record that this target has run

.PHONY: kops
## Toolbox for kops
kops: module

.PHONY: kubernetes
## Toolbox for kubernetes
kubernetes: module

.PHONY: helm
## Toolbox for helm
helm: module

.PHONY: terraform
## Toolbox for terraform
terraform: module
