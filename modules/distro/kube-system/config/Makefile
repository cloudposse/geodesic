include ../../../Makefile.helpers
include ../../helpers/Makefile.config

## Configure DNS
dns:
	$(call chart-values,$@,cloudposse-incubator/route53-kubernetes)

## Configure SSL
ssl:
	$(call chart-values,$@,cloudposse-incubator/kube-lego)

## Configure SSH
ssh:
	$(call chart-values,$@,cloudposse-incubator/github-authorized-keys)

## Configure UI
ui:
	$(call chart-values,$@,cloudposse-incubator/kubernetes-dashboard)

## Configure Etcd Operator
etcd-operator:
	$(call chart-values,$@,stable/etcd-operator)

## Configure log aggregation
logs:
	$(call chart-values,$@,cloudposse-incubator/syslog-forwarder)

## Configure monitoring
monitoring:
	$(call chart-values,$@,cloudposse-incubator/heapster)

## Configure metrics
metrics:
	$(call chart-values,$@,cloudposse-incubator/kube-state-metrics)

## Configure Data Dog
#dd:
#	$(call chart-values,$@,stable/datadog)
