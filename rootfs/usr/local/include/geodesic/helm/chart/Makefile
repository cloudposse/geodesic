PACKAGE_PATH ?= package/

ifneq ($(LINT),true)
	AVAILABLE_PACKAGES ?= $(shell ls -1 $(PACKAGE_PATH))
	CONFIGURED_PACKAGES ?= $(shell find $(HELM_VALUES_PATH) -type f -name '*.yaml' | xargs -n 1 -I '{}' basename {} .yaml)
	INSTALLED_PACKAGES ?= $(shell helm list --short | xargs -n1 -I'{}' sh -c '[ -f $(HELM_VALUES_PATH)/{}.yaml ] && echo {}')
endif

## Very basic validation that configuration directory exists for this namespace
validate:
	@if [ ! -d  $(HELM_VALUES_PATH) ]; then \
		echo "No values found in $(HELM_VALUES_PATH)"; \
		exit 1; \
	fi

## List configured packages for this namespace
list-available:
	@echo "Packages available:"
	@echo $(AVAILABLE_PACKAGES) | xargs -n 1 printf -- ' - %s\n'

## List configured packages for this namespace
list-configured: validate
	@echo "Packages configured:"
	@echo $(CONFIGURED_PACKAGES) | xargs -n 1 printf -- ' - %s\n'

## List installed packages for this namespace
list-installed: validate
	@echo "Packages installed:"
	@helm list `echo $(AVAILABLE_PACKAGES) | xargs -n 1 printf -- '%s\n' | paste -s -d\| - | xargs printf '^(%s)$$'`

## List configurations for this namespace
list-configs: validate
	@echo "Packages configured:"
	@find $(HELM_VALUES_PATH) -type f -name '*.yaml' | xargs -n 1 printf ' - %s\n'

## Install package
install:
	@make -f $(PACKAGE_PATH)/$(NAME) $@

## Uninstall package
uninstall:
	@make -f $(PACKAGE_PATH)/$(NAME) $@

## Upgrade package
upgrade:
	@make -f $(PACKAGE_PATH)/$(NAME) $@

## Edit package configuration
edit:
	@make -f $(PACKAGE_PATH)/$(NAME) $@

## Initialize package configuration
init:
	@make -f $(PACKAGE_PATH)/$(NAME) $@

