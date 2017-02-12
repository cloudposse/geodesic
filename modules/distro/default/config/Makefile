include helpers
include distro/config

## Configure Ingress Load Balancer
lb:
	$(call chart-values,$@,cloudposse-incubator/nginx-ingress)

## Configure CI/CD
ci:
	$(call chart-values,$@,cloudposse-incubator/jenkins)

