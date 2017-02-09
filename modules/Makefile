-include Makefile.*

.PHONY : deps
## Setup environment
deps:
	@cloud config create-bucket

.PHONY : up
## Bring up a new cluster
up:
	@cloud kops $@ wait-until-ready

.PHONY : down
## Tear down an existing cluster
down:
	@cloud kops $@

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

## Bootstrap the overall system
.PHONY : bootstrap
bootstrap: require-aws-profile require-cluster-online
	@cloud kops is-online || (echo "Cluster is unavilable. Did you run 'make up'?"; exit 1)
	@[ ! -f $(GEODESIC_PATH)/state/.bootstrapped ] || (echo "Cluster already bootstraped"; exit 1)
	@cloud kubernetes create-dockercfg     # Set the Docker Registry secret
	@cloud helm init                       # Initalize helm for packages
	@cloud helm init-repos                 # Initalize helm for packages
	@cloud helm update		               # Update repo index
	@cloud distro kube-system config all   # Configure essential k8s services
	@cloud distro default config all       # Configure default namespace
	@cloud config init-serial              # Initialize the optimistic locking mechanism
	@touch $(GEODESIC_PATH)/state/.bootstrapped
	@cloud config push                     # Save the configuration

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

.PHONY: terraform
## Manage terraform
terraform: module
