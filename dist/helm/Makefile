init:
	helm init

upgrade:
	kubectl --namespace=kube-system set image deployments/tiller-deploy tiller=gcr.io/kubernetes-helm/tiller:v2.1.0
