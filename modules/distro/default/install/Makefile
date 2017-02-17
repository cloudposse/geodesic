# Install the default namespace; order of targets in this file is the order in which they will get installed
include helpers
include distro/install

## Install Ingress Load Balancer
lb:
	$(call chart-install,cloudposse-incubator/nginx-ingress)

## Install CI/CD
ci:
	$(call chart-install,cloudposse-incubator/jenkins)

