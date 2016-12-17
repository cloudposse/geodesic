DOCKER_IMAGE ?= cloudposse/geodesic
DOCKER_TAG ?= dev

deps:
	git submodule update --recursive --remote

build:
	docker build -t $(DOCKER_IMAGE):$(DOCKER_TAG) .

install: deps
	cp -a contrib/geodesic /usr/local/bin
