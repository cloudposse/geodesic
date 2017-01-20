include ../../../Makefile.helpers


## Install Ingress Load Balancer
lb:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/nginx-ingress

## Install CI/CD
ci:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-jenkins/jenkins

