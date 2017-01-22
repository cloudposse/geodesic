include ../Makefile.helpers
-include Makefile.*

## Init the client & server
init:
	@helm init

## Init the helm client
init-client:
	@helm init --client-only

## Init the repositories
init-repos:
	@helm repo add cloudposse-stable https://charts.cloudposse.com/stable
	@helm repo add cloudposse-incubator https://charts.cloudposse.com/incubator

## Upgrade tiller
upgrade:
	kubectl --namespace=kube-system set image deployments/tiller-deploy tiller=gcr.io/kubernetes-helm/tiller:v$(HELM_VERSION)
