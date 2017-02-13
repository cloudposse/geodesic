include helpers
include all

CLUSTER_REPO_PATH ?= $(LOCAL_STATE)/clusters/$(CLUSTER_NAME)
MESSAGE ?= "Automatic commit"

validate:
	$(call assert-set,CLUSTER_NAME)

## Create a new cluster repo
create: validate test
	@[ -d $(CLUSTER_REPO_PATH) ] || mkdir -p $(CLUSTER_REPO_PATH)
	@[ -d $(CLUSTER_REPO_PATH)/.git ] || git -C $(CLUSTER_REPO_PATH) init
	@hub -C $(CLUSTER_REPO_PATH) create

## Clone an existing cluster repo
clone: validate test
	@git -C $(CLUSTER_REPO_PATH) clone 
	@cloud hub update

## Pull down updates
update: validate test
	@git -C $(CLUSTER_REPO_PATH) pull origin
	@git -C $(CLUSTER_REPO_PATH) submodule update --init --remote

## Push changes to github
push: validate test
	@git -C $(CLUSTER_REPO_PATH) push origin

## Commit changes 
commit: test
	@git -C $(CLUSTER_REPO_PATH) commit -a --message "$(MESSAGE)"

## Show status of cluster repo
status:
	@git -C $(CLUSTER_REPO_PATH) status -s

## Test github connection
test:
	@set -o pipefail;  \
	(ssh  -o StrictHostKeyChecking=no git@github.com 2>&1 | grep 'successfully authenticated' | cut -d' ' -f2 | cut -d'!' -f1) || \
	(echo "Failed to authetnicate with github. Make sure your SSH keys have been added to your agent."; exit 1)
