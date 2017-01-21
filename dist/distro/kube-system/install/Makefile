include ../../../Makefile.helpers
include ../../Makefile.install

## Install DNS
dns:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/route53-kubernetes

## Install SSL
ssl:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/kube-lego

## Install SSH
ssh:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/github-authorized-keys

## Install UI
ui:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/kubernetes-dashboard

## Install Etcd Operator
etcd-operator:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml stable/etcd-operator

## Install log aggregation
logs:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/syslog-forwarder

## Install monitoring
monitoring:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/heapster

## Install metrics
metrics:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-incubator/kube-state-metrics

## Install Data Dog
dd:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml cloudposse-jenkins/datadog

