export DOCKER_IMAGE ?= nikiai/geodesic-base
export DOCKER_TAG ?= alpine
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS ?= --no-cache --squash --rm

include $(shell curl --silent -o .build-harness "https://raw.githubusercontent.com/cloudposse/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

all: init deps lint build install run

lint:
	@LINT=true \
	 find rootfs/usr/local/include -type f '!' -name '*.sample' -exec \
			 /bin/sh -c 'echo "==> {}">/dev/stderr; make --include-dir=rootfs/usr/local/include/ --just-print --dry-run --recon --no-print-directory --quiet --silent -f {}' \; > /dev/null
	@make bash:lint

deps:
	@exit 0

build:
	@make --no-print-directory docker:build

cleanup:
	docker container prune -f && docker image prune -f

push:
	docker push $(DOCKER_IMAGE)

install:
	@docker run --rm -e CLUSTER=galaxy $(DOCKER_IMAGE_NAME) | sudo bash -s dev

run:
	@geodesic
