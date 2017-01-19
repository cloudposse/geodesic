IMAGE ?= cloudposse/geodesic
TAG ?= dev

SHELL = /bin/bash
export BUILD_HARNESS_PATH ?= $(shell until [ -d "build-harness" ] || [ "`pwd`" == '/' ]; do cd ..; done; pwd)/build-harness
-include $(BUILD_HARNESS_PATH)/Makefile

deps:
	@make --no-print-directory git:submodules-update

build:
	@make --no-print-directory docker:build

install:
	@DOCKER_TAG=$(TAG) REQUIRE_PULL=false ./install.sh

.PHONY : init
## Init build-harness
init:
	@curl --retry 5 --retry-delay 1 https://raw.githubusercontent.com/cloudposse/build-harness/master/bin/install.sh | bash

.PHONY : clean
## Clean build-harness
clean:
	rm -rf $(BUILD_HARNESS_PATH)