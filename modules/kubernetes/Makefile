include ../Makefile.helpers
-include Makefile.*

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
set-dockercfg: validate
	@kubectl create secret docker-registry dockercfg \
	  --docker-server=$(DOCKER_REGISTRY_SERVER) \
	  --docker-username=$(DOCKER_USER) \
	  --docker-password=$(DOCKER_PASSWORD) \
	  --docker-email=$(DOCKER_EMAIL)

## Setup API tunnel to localhost
proxy:
	@echo "Kubernetes API exposed on http://127.0.0.1:8001/"
	@kubectl proxy --address=0.0.0.0 --port 8001 || true



