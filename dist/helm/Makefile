include ../Makefile.helpers
include Makefile.*

## Init the client & server
init:
	helm init

## Init the helm client
init-client:
	helm init --client-only

## Upgrade tiller
upgrade:
	kubectl --namespace=kube-system set image deployments/tiller-deploy tiller=gcr.io/kubernetes-helm/tiller:v$(HELM_VERSION)
