include Makefile.*

linux:
	@echo "Not implemented" && exit 1

darwin:
	@which -s brew || (echo "Please install brew"; exit 1)
	@which -s kubectl || brew install kubectl
	@which -s aws || brew install aws

deps: $(OS)
	@[ -x $(KOPS_BIN) ] || (mkdir -p bin/ && curl --location -s -o $(KOPS_BIN) $(KOPS_DOWNLOAD_URL) && chmod 755 $(KOPS_BIN))
	@aws s3 mb $(KOPS_STATE)

update:
	@$(KOPS_BIN) update cluster \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

up:
	@echo "Creating cluster $(KOPS_NAME)..."
	@$(KOPS_BIN) create cluster \
			--cloud=$(KOPS_CLOUD) \
			--zones=$(KOPS_ZONES) \
      --dns-zone=$(KOPS_DNS_ZONE) \
      --associate-public-ip=$(KOPS_ASSOCIATE_PUBLIC_IP) \
	    --admin-access=$(KOPS_ADMIN_ACCESS) \
      --node-count=$(KOPS_NODE_COUNT) \
      --node-size=$(KOPS_NODE_SIZE) \
      --master-size=$(KOPS_MASTER_SIZE) \
      --master-zones=$(KOPS_MASTER_ZONES) \
      --kubernetes-version=$(KOPS_KUBERNETES_VERSION) \
      --state=$(KOPS_STATE) \
      --name=$(KOPS_NAME) \
      --yes

down:
	@$(KOPS_BIN) delete cluster \
      --name=$(KOPS_NAME) \
      --state=$(KOPS_STATE) \
      --yes

ssh:
	@ssh admin@api.$(KOPS_NAME)

install-dashboard:
	@kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/kubernetes-dashboard/v1.4.0.yaml

install-heapster:
	@kubectl create -f https://raw.githubusercontent.com/kubernetes/kops/master/addons/monitoring-standalone/v1.2.0.yaml

# https://github.com/kubernetes/kubernetes/tree/master/examples/mysql-wordpress-pd
# https://github.com/kubernetes/kops/pull/906
# https://github.com/jenkinsci/kubernetes-plugin
# https://wiki.jenkins-ci.org/display/JENKINS/GitHub+OAuth+Plugin
# https://jenkins.io/solutions/pipeline/
# https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes
# ingress controller: https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes/blob/master/jenkins/k8s/lb/ingress.yaml
#                     http://kubernetes.io/docs/user-guide/ingress/
# http://blog.couchbase.com/2016/july/stateful-containers-kubernetes-amazon-ebs

# https://github.com/kubernetes/kubernetes/tree/master/examples/newrelic (useful for github-authorized-keys reference)
# https://github.com/kubernetes/kubernetes/blob/master/examples/volumes/aws_ebs/aws-ebs-web.yaml
# https://github.com/kubernetes/kubernetes/tree/master/examples/volumes/nfs

# helm charts: https://github.com/kubernetes/charts
# https://github.com/kubernetes/charts/tree/master/stable/jenkins
# openvpn
# https://github.com/carlossg/kubernetes-jenkins
# https://github.com/offlinehacker/openvpn-k8s
# https://github.com/redspread/kube-openvpn
# https://github.com/pieterlange/kube-openvpn
# https://github.com/djenriquez/vault-ui

