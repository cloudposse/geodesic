include ../../../Makefile.helpers

NAMESPACE ?= $(shell basename `pwd`)

## Uninstall Ingress Load Balancer
lb:
	@helm delete $@ --purge

## Uninstall CI/CD
ci:
	@helm delete $@ --purge

