# Install the default namespace; order of targets in this file is the order in which they will get installed
include helpers
include distro/install

## Install Ingress Load Balancer
lb:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/nginx-ingress

## Install CI/CD
ci:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/jenkins

