include helpers
include distro/config

## Configure Ingress Load Balancer
lb:
	$(call chart-config,cloudposse-incubator/nginx-ingress)

## Configure CI/CD
ci:
	$(call chart-config,cloudposse-incubator/jenkins)

