include helpers
include all

export TF_VAR_dns_zone_id ?= Z2TNGI2B6LNBQN
export TF_VAR_kubernetes_cluster ?= $(KOPS_NAME)

## Apply terraform configuration
#apply:
#	@terraform apply \
#	TF_VAR_elb_zone_id ?= $(shell aws elb describe-load-balancers --region $(KOPS_REGION) --query 'LoadBalancerDescriptions[?CanonicalHostedZoneName==`$(TF_VAR_elb_dns_name)`].CanonicalHostedZoneNameID' --output text) \
#	TF_VAR_elb_dns_name="$(shell kubectl get svc ingress-nginx --output='jsonpath={..hostname}')" \

