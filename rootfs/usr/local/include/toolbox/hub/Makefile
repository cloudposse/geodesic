include helpers
include all

CLUSTER_REPO_PATH ?= $(LOCAL_STATE)/clusters/$(CLUSTER_NAME)
MESSAGE ?= Automatic commit
REMOTE ?= origin
BRANCH ?= master

deps: 
	@ls -1 $(LOCAL_STATE)/clusters/ | xargs -I '{}' adduser -h $(LOCAL_STATE)/clusters/{} -s /sbin/nologin -g 'Cluster Repo' -D -H {} >/dev/null 2>&1 || true

validate:
	$(call assert-set,CLUSTER_NAME)

## Create a new private cluster repo
create: validate test deps
	@[ -d $(CLUSTER_REPO_PATH) ] || mkdir -p $(CLUSTER_REPO_PATH)
	@[ -d $(CLUSTER_REPO_PATH)/.git ] || git -C $(CLUSTER_REPO_PATH) init
	@cd $(CLUSTER_REPO_PATH) && \
		hub create -p -d "Geodesic cluster configuration for $(CLUSTER_NAME)" $(GITHUB_ORG)/$(CLUSTER_NAME) 

## Clone an existing cluster repo
clone: validate test deps
	$(call assert-set,GITHUB_ORG)
	@git clone -b $(BRANCH) git@github.com:$(GITHUB_ORG)/$(CLUSTER_NAME) $(CLUSTER_REPO_PATH)
	@cloud hub pull

## Update local cluster repo 
update:
	@if [ -d "$(CLUSTER_REPO_PATH)" ]; then \
		cloud hub pull; \
	else \
		cloud hub clone; \
	fi

## Pull down updates
pull: validate test deps
	@git -C $(CLUSTER_REPO_PATH) pull $(REMOTE) $(BRANCH)
	@git -C $(CLUSTER_REPO_PATH) submodule update --init --remote

## Push changes to github
push: validate test deps
	@git -C $(CLUSTER_REPO_PATH) push $(REMOTE) $(BRANCH)

## Commit changes 
commit:
	@git -C $(CLUSTER_REPO_PATH) commit -a --message "$(MESSAGE)"

## Show status of cluster repo
status:
	@git -C $(CLUSTER_REPO_PATH) status -s

## Test github connection
test:
	@set -o pipefail;  \
	 GITHUB_USERNAME=$$(ssh  -o StrictHostKeyChecking=no git@github.com 2>&1 | grep 'successfully authenticated' | cut -d' ' -f2 | cut -d'!' -f1); \
	[ -n "$$GITHUB_USERNAME" ] || (echo "Failed to authetnicate with github. Make sure your SSH keys have been added to your agent."; exit 1)
