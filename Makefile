export DOCKER_ORG ?= cloudposse
export DOCKER_IMAGE ?= $(DOCKER_ORG)/geodesic
export DOCKER_BASE_TAG ?= dev
export DOCKER_BASE_OS ?= debian
export DOCKER_TAG ?= $(DOCKER_BASE_TAG)-$(DOCKER_BASE_OS)
export DOCKER_IMAGE_NAME_BASE ?= $(DOCKER_IMAGE):$(DOCKER_BASE_TAG)
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_FILE ?= os/$(DOCKER_BASE_OS)/Dockerfile.$(DOCKER_BASE_OS)
export DOCKER_DEV_BUILD_FLAGS = --build-arg DEV_VERSION=$(shell printf "%s/%s" $$(git describe --tags 2>/dev/null || echo "unk") $$(git branch --no-color --show-current || echo "unk"))
# Force Alpine build to be amd64, allow Debian build to be alternate platform by setting BUILD_ARCH
export BUILD_ARCH ?= $(if $(subst alpine,,$(DOCKER_BASE_OS)),,amd64)
export DOCKER_ARCH_BUILD_FLAGS = $(if $(BUILD_ARCH), --platform=linux/$(BUILD_ARCH),)
# Set DOCKER_EXTRA_BUILD_FLAGS to add to the default build flags, set DOCKER_BUILD_FLAGS to override
export DOCKER_BUILD_FLAGS ?= $(DOCKER_EXTRA_BUILD_FLAGS) $(DOCKER_ARCH_BUILD_FLAGS) $(DOCKER_DEV_BUILD_FLAGS)
export INSTALL_PATH ?= /usr/local/bin
export APP_NAME ?= geodesic

include $(shell curl --silent -o .build-harness "https://raw.githubusercontent.com/cloudposse/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

all: init deps lint build install run/new

%.all: init deps lint %.build %.install run/new
	@exit 0

# This sets the BASE_OS env var for the given targets
%.build %.install %.all: DOCKER_BASE_OS = $*

lint: deps
	@if [ -d rootfs/usr/local/include ]; then \
	  LINT=true \
		find rootfs/usr/local/include -type f '!' -name '*.sample' -exec \
		/bin/sh -c 'echo "==> {}">/dev/stderr; make --include-dir=rootfs/usr/local/include/ --just-print --dry-run --recon --no-print-directory --quiet --silent -f {}' \; > /dev/null; \
	fi

deps: init
	@exit 0

%.build:
	@make --no-print-directory docker:build
	docker tag $(DOCKER_IMAGE_NAME) $(DOCKER_IMAGE_NAME_BASE)

%.install:
	@docker run --rm --env APP_NAME --env DOCKER_IMAGE --env DOCKER_TAG --env INSTALL_PATH $(DOCKER_IMAGE_NAME) | bash -s $(DOCKER_TAG)

build: $(DOCKER_BASE_OS).build

install: $(DOCKER_BASE_OS).install

run:
	@geodesic

%.run: %.build %.install
	@geodesic

run/check:
	@if [[ -n "$$(docker ps --format '{{ .Names }}' --filter name="^/$(APP_NAME)\$$")" ]]; then \
		printf "**************************************************************************\n" ; \
		printf "Not launching new container because old container is still running.\n"; \
		printf "Exit all running container shells gracefully or kill the container with\n\n"; \
		printf "  docker kill %s\n\n" "$(APP_NAME)" ; \
		printf "**************************************************************************\n" ; \
		exit 9 ; \
	fi

run/new: run/check run
	@exit 0

bash/fmt:
	shfmt -l -w $(PWD)/rootfs

bash/fmt/check:
	shfmt -d $(PWD)/rootfs

.PHONY:  all %.all build %.build install %.install run %.run run/new run/check
