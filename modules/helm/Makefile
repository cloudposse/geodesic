include helpers
include all

## Init the client & server
init:
	@$(HELM) init

## Init the helm client
init-client:
	@$(HELM) init --client-only

## Init the repositories
init-repos:
	@$(HELM) repo add cloudposse-stable https://charts.cloudposse.com/stable
	@$(HELM) repo add cloudposse-incubator https://charts.cloudposse.com/incubator

## Update repo indexes
update:
	@$(HELM) repo update

## Upgrade tiller
upgrade:
	kubectl --namespace=kube-system set image deployments/tiller-deploy tiller=gcr.io/kubernetes-helm/tiller:v$(HELM_VERSION)
