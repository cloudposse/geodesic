include ../../../Makefile.helpers
include ../../Makefile.config

## Configure Ingress Load Balancer
lb:
	$(call chart-values,$@,cloudposse-incubator/nginx-ingres)

## Congigure CI/CD
ci:
	$(call chart-values,$@,cloudposse-incubator/jenkins)

