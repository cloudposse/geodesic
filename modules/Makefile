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
create:
	# require assume role
	# run `cloud configure`
	# create bucket
	# move config to bucket
	# initialize git repo

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
	@cloud kubernetes create-dockercfg     # Set the Docker Registry secret
	@cloud helm init                       # Initalize helm for packages
	@cloud helm init-repos                 # Initalize helm for packages
	@cloud helm update                     # Update repo index
	@cloud distro kube-system config all   # Configure essential k8s services
	@cloud distro default config all       # Configure default namespace
	@touch $(REMOTE_STATE)/.bootstrapped   # Record that this target has run

.PHONY: distro
## Manage distributions
distro: module

.PHONY: kops
## Manage kops
kops: module

.PHONY: kubernetes
## Manage kubernetes
kubernetes: module
  
.PHONY: helm
## Manage helm
helm: module

.PHONY: hub
## Manage cluster github repo
hub: module

.PHONY: terraform
## Manage terraform
terraform: module
