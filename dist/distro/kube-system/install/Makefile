include ../../../Makefile.helpers

## Install DNS
dns:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/route53-kubernetes

## Install SSL
ssl:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/kube-lego

## Install SSH
ssh:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/github-authorized-keys

## Install UI
ui:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/kubernetes-dashboard

## Install Etcd Operator
etcd-operator:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml stable/etcd-operator

## Install log aggregation
logs:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/syslog-forwarder

## Install monitoring
monitoring:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-incubator/heapster

## Install Data Dog
dd:
	@helm install --namespace kube-system --name $@ --values $(HELM_VALUES_PATH)/$@.yaml cloudposse-jenkins/datadog

