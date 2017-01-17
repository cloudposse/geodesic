include ../../Makefile.helpers


## Install
install:
	helm install --namespace kube-system --name dns --values $(HELM_VALUES_PATH)/route53-kubernetes.yaml cloudposse-incubator/route53-kubernetes
	helm install --namespace kube-system --name ssl --values $(HELM_VALUES_PATH)/kube-lego.yaml cloudposse-incubator/kube-lego
	helm install --namespace kube-system --name ssh --values $(HELM_VALUES_PATH)/github-authorized-keys.yaml cloudposse-incubator/github-authorized-keys
	helm install --namespace kube-system --name ui --values $(HELM_VALUES_PATH)/kubernetes-dashboard.yaml cloudposse-incubator/kubernetes-dashboard
	helm install --namespace kube-system --name etcd-operator --values $(HELM_VALUES_PATH)/etcd-operator.yaml stable/etcd-operator
	helm install --namespace kube-system --name logs --values $(HELM_VALUES_PATH)/syslog-forwarder.yaml cloudposse-incubator/syslog-forwarder
	helm install --namespace kube-system --name monitoring --values $(HELM_VALUES_PATH)/heapster.yaml cloudposse-incubator/heapster
#	helm install --namespace kube-system --name dd --values $(HELM_VALUES_PATH)/datadog.yaml cloudposse-jenkins/datadog

