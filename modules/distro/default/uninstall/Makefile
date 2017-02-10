include ../../../Makefile.helpers
include ../../helpers/Makefile.uninstall

## Uninstall Ingress Load Balancer
lb: confirm
	@helm delete $@ --purge

## Uninstall CI/CD
ci: confirm
	@helm delete $@ --purge

