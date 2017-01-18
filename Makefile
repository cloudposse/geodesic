IMAGE ?= cloudposse/geodesic
TAG ?= dev

default: build

deps:
	git submodule update --remote

build: 
	docker build -t $(IMAGE):$(TAG) .

install:
	@DOCKER_TAG=$(TAG) REQUIRE_SUDO=false REQUIRE_PULL=false ./install.sh
