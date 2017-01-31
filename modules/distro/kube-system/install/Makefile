# Install the kube-system namespace; order of targets in this file is the order in which they will get installed

include ../../../Makefile.helpers
include ../../Makefile.install

## Install Etcd Operator
etcd-operator:
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml stable/etcd-operator

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
	@helm install --namespace $(NAMESPACE) --name $@ --values $(HELM_VALUES_PATH)/$(NAMESPACE)/$@.yaml stable/datadog

