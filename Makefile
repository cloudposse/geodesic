export DOCKER_IMAGE ?= cloudposse/geodesic
export DOCKER_TAG ?= dev
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS = 

-include Makefile.*

SHELL = /bin/bash
export BUILD_HARNESS_PATH ?= $(shell until [ -d "build-harness" ] || [ "`pwd`" == '/' ]; do cd ..; done; pwd)/build-harness
-include $(BUILD_HARNESS_PATH)/Makefile

all: init deps build install run

deps:
	@make --no-print-directory git:submodules-update

build:
	@make --no-print-directory docker:build

install:
	@REQUIRE_PULL=false public/install.sh

run:
	@geodesic

.PHONY : init
## Init build-harness
init:
	@curl --retry 5 --retry-delay 1 https://raw.githubusercontent.com/cloudposse/build-harness/master/bin/install.sh | bash

.PHONY : clean
## Clean build-harness
clean:
	rm -rf $(BUILD_HARNESS_PATH)
