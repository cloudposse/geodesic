export CLUSTER = dev.niki.ai
export DOCKER_ORG = nikiai
export DOCKER_IMAGE = $(DOCKER_ORG)/$(CLUSTER)
export DOCKER_TAG = dev
export DOCKER_IMAGE_NAME = $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS = --squash --rm

-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

all: deps build push install run

deps:
	@exit 0

build:
	@make --no-print-directory docker:build

push:
	docker push $(DOCKER_IMAGE)

install:
	@docker run --rm $(DOCKER_IMAGE_NAME) > test.sh

run:
	$(CLUSTER)