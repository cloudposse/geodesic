include helpers
include all

CHART_PATH ?= ../

ifneq ($(LINT),true)
	AVAILABLE_CHARTS ?= $(shell ls -1 $(CHART_PATH) | grep -v list)
	CONFIGURED_CHARTS ?= $(shell find $(HELM_VALUES_PATH) -type f -name '*.yaml' | xargs -n 1 -I '{}' basename {} .yaml)
	INSTALLED_CHARTS ?= $(shell helm list --short | xargs -n1 -I'{}' sh -c '[ -f $(HELM_VALUES_PATH)/{}.yaml ] && echo {}')
endif

## Very basic validation that configuration directory exists
validate:
	@if [ ! -d  $(HELM_VALUES_PATH) ]; then \
		echo "No values found in $(HELM_VALUES_PATH)"; \
		exit 1; \
	fi

## List configured charts
available:
	@echo "Charts available:"
	@echo $(AVAILABLE_CHARTS) | xargs -n 1 printf -- ' - %s\n'

## List configured charts for this namespace
configured: validate
	@echo "Charts configured:"
	@echo $(CONFIGURED_CHARTS) | xargs -n 1 printf -- ' - %s\n'

## List installed charts
installed: validate
	@echo "Charts installed:"
	@helm list `echo $(AVAILABLE_CHARTS) | xargs -n 1 printf -- '%s\n' | paste -s -d\| - | xargs printf '^(%s)$$'`

## List configurations
configs: validate
	@echo "Charts configured:"
	@find $(HELM_VALUES_PATH) -type f -name '*.yaml' | xargs -n 1 printf ' - %s\n'
