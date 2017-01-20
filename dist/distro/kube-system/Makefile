include ../../Makefile.helpers

export NAMESPACE ?= $(shell basename `pwd`)
export DEFAULT_PACKAGES ?= dns ssl ssh ui etcd-operator logs monitoring

## Install default packages for kube-system
install: confirm
	@make -C install $(DEFAULT_PACKAGES)

## Install default packages for kube-system
uninstall: confirm
	@make -C uninstall $(DEFAULT_PACKAGES)
