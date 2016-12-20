IMAGE ?= cloudposse/geodesic
TAG ?= dev

default: build

deps:
	git submodule update --remote

build: 
	docker build -t $(IMAGE):$(TAG) .

install:
	docker run --tty $(IMAGE):$(TAG) > /usr/local/bin/geodesic
	chmod 755 /usr/local/bin/geodesic 
