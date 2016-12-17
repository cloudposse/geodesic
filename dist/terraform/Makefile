export TF_VAR_dns_zone_id ?= Z2TNGI2B6LNBQN
export TF_VAR_elb_dns_name ?= a2abcf366bdb511e6afd006acd2a6d48-873162265.us-west-2.elb.amazonaws.com
export TF_VAR_elb_zone_id ?= $(shell aws elb describe-load-balancers --region $(KOPS_REGION) --query 'LoadBalancerDescriptions[?CanonicalHostedZoneName==`$(TF_VAR_elb_dns_name)`].CanonicalHostedZoneNameID' --output text)
export TF_VAR_kubernetes_cluster ?= $(KOPS_NAME)

apply:
	terraform apply

register-elb-dns:
	export TF_VAR_elb_dns_name="$(shell kubectl get svc ingress-nginx --output='jsonpath={..hostname}')"; \
  make apply
