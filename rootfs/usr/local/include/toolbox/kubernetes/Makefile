include helpers
include all

KUBERNETES_API_PORT ?= 8001

## Validate environment is setup correctly
validate:
	$(call assert-set,DOCKER_REGISTRY_SERVER)
	$(call assert-set,DOCKER_USER)
	$(call assert-set,DOCKER_PASSWORD)
	$(call assert-set,DOCKER_EMAIL)
	

## Set the default context
#set-context:
#	kubectl config set-context demo --namespace=demo

## Set the docker-registry secret (See: https://kubernetes.io/docs/user-guide/images/)
create-dockercfg: validate delete-dockercfg
	@kubectl create secret docker-registry dockercfg \
	  --docker-server=$(DOCKER_REGISTRY_SERVER) \
	  --docker-username=$(DOCKER_USER) \
	  --docker-password=$(DOCKER_PASSWORD) \
	  --docker-email=$(DOCKER_EMAIL)

## Delete the docker-registry secret (if it exists)
delete-dockercfg:
	@kubectl delete secret docker-registry dockercfg >/dev/null 2>&1 || true

## Setup API tunnel to localhost
proxy:
	@echo "Kubernetes API exposed on http://127.0.0.1:$(KUBERNETES_API_PORT)/"
	@kubectl proxy --address=0.0.0.0 --port $(KUBERNETES_API_PORT) || true



