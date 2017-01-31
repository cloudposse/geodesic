include ../../../Makefile.helpers
include ../../Makefile.install

## Install Ingress Load Balancer
lb:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/nginx-ingress

## Install CI/CD
ci:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/jenkins

