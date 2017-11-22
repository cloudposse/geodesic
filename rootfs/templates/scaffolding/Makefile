export CLUSTER_NAME ?= $(shell basename `pwd`)
export DOCKER_ORG ?= {{ getenv "DOCKER_ORG" "cloudposse" }}
export DOCKER_IMAGE ?= $(DOCKER_ORG)/$(CLUSTER_NAME)
export DOCKER_TAG ?= dev
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS = 

-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

all: init deps build install run

deps:
	@exit 0

build:
	@make --no-print-directory docker:build

push:
	docker push $(DOCKER_IMAGE)

install:
	@docker run --rm $(DOCKER_IMAGE_NAME) | sudo bash -s dev

run:
	$(CLUSTER_NAME)
