include ../../Makefile.helpers

## Install the default namespace
install:
	helm install --namespace default --name lb --values $(HELM_VALUES_PATH)/nginx-ingress.yaml cloudposse-incubator/nginx-ingress
	helm install --namespace default --name ci --values $(HELM_VALUES_PATH)/jenkins.yaml cloudposse-jenkins/jenkins

