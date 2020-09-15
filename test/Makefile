all: export INSTALL_PATH=$(CURDIR)/.packages
all:
	set -ex; \
	cd ../; \
	make packages/reinstall/shfmt; \
	make bash/fmt/check; \
	make deps; \
	make lint; 


