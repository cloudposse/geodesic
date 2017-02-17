include helpers
include distro/config

## Configure DNS
dns:
	$(call chart-config,cloudposse-incubator/route53-kubernetes)

## Configure SSL
ssl:
	$(call chart-config,cloudposse-incubator/kube-lego)

## Configure SSH
ssh:
	$(call chart-config,cloudposse-incubator/github-authorized-keys)

## Configure UI
ui:
	$(call chart-config,cloudposse-incubator/kubernetes-dashboard)

## Configure Etcd Operator
etcd-operator:
	$(call chart-config,stable/etcd-operator)

## Configure log aggregation
logs:
	$(call chart-config,cloudposse-incubator/syslog-forwarder)

## Configure monitoring
monitoring:
	$(call chart-config,cloudposse-incubator/heapster)

## Configure metrics
metrics:
	$(call chart-config,cloudposse-incubator/kube-state-metrics)

## Configure Data Dog
#dd:
#	$(call chart-config,$@,stable/datadog)
