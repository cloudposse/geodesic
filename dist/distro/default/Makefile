include ../../Makefile.helpers

export NAMESPACE ?= $(shell basename `pwd`)
export DEFAULT_PACKAGES ?= lb ci

## Install the default namespace
install: confirm
	@make -C install $(DEFAULT_PACKAGES)

## Uninstall the default namespace
uninstall: confirm
	@make -C uninstall $(DEFAULT_PACKAGES)

