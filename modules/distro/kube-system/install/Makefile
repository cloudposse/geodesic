# Install the kube-system namespace; order of targets in this file is the order in which they will get installed
include helpers
include distro/install

## Install Etcd Operator
etcd-operator:
	$(call chart-install,stable/etcd-operator)

## Install DNS
dns:
	$(call chart-install,cloudposse-incubator/route53-kubernetes)

## Install SSL
ssl:
	$(call chart-install,cloudposse-incubator/kube-lego)
  
## Install SSH
ssh:
	$(call chart-install,cloudposse-incubator/github-authorized-keys)

## Install UI
ui:
	$(call chart-install,cloudposse-incubator/kubernetes-dashboard)

## Install log aggregation
logs:
	$(call chart-install,cloudposse-incubator/syslog-forwarder)

## Install monitoring
monitoring:
	$(call chart-install,cloudposse-incubator/heapster)

## Install metrics
metrics:
	$(call chart-install,cloudposse-incubator/kube-state-metrics)

## Install Data Dog
dd:
	$(call chart-install,stable/datadog)

