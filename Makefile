export DOCKER_ORG ?= cloudposse
export DOCKER_IMAGE ?= $(DOCKER_ORG)/geodesic
export DOCKER_BASE_TAG ?= dev
export DOCKER_BASE_OS ?= debian
export DOCKER_TAG ?= $(DOCKER_BASE_TAG)-$(DOCKER_BASE_OS)
export DOCKER_IMAGE_NAME_BASE ?= $(DOCKER_IMAGE):$(DOCKER_BASE_TAG)
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_FILE ?= os/$(DOCKER_BASE_OS)/Dockerfile.$(DOCKER_BASE_OS)
export DOCKER_BUILD_FLAGS = --build-arg DEV_VERSION=$(shell printf "%s/%s" $$(git describe --tags 2>/dev/null || echo "unk") $$(git branch --no-color --show-current || echo "unk"))
export INSTALL_PATH ?= /usr/local/bin
export APP_NAME ?= geodesic

include $(shell curl --silent -o .build-harness "https://raw.githubusercontent.com/cloudposse/build-harness/master/templates/Makefile.build-harness"; echo .build-harness)

all: init deps lint build install run/new

%.all: init deps lint %.build %.install run/new
	@exit 0

# This sets the BASE_OS env var for the given targets
%.build %.install %.all: DOCKER_BASE_OS = $*

lint: deps
	@LINT=true \
	 find rootfs/usr/local/include -type f '!' -name '*.sample' -exec \
			 /bin/sh -c 'echo "==> {}">/dev/stderr; make --include-dir=rootfs/usr/local/include/ --just-print --dry-run --recon --no-print-directory --quiet --silent -f {}' \; > /dev/null

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

.PHONY: geodesic_apkindex.md5 geodesic_aptindex.md5 all %.all build %.build install %.install run %.run run/new run/check

apk-update geodesic_apkindex.md5: DOCKER_BASE_OS = alpine
apk-update geodesic_apkindex.md5:
	@echo geodesic_apkindex.md5 old $$(cat os/alpine/geodesic_apkindex.md5 || echo '<not found>')
	@docker run --rm $(DOCKER_IMAGE_NAME) -c \
	'apk update >/dev/null && geodesic-apkindex-md5' > os/alpine/geodesic_apkindex.md5
	@echo geodesic_apkindex.md5 new $$(cat os/alpine/geodesic_apkindex.md5 || echo '<not found>')

apt-update geodesic_aptindex: DOCKER_BASE_OS = debian
apt-update geodesic_aptindex.md5:
	@echo geodesic_aptindex.md5 old $$(cat os/debian/geodesic_aptindex.md5 || echo '<not found>')
	@docker run --rm $(DOCKER_IMAGE_NAME) -c \
	'apt-get update >/dev/null && geodesic-aptindex-md5' > os/debian/geodesic_aptindex.md5
	@echo geodesic_aptindex.md5 new $$(cat os/debian/geodesic_aptindex.md5 || echo '<not found>')
