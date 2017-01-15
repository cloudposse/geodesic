include ../Makefile.helpers
-include Makefile.*
## Set the default context
set-context:
	kubectl config set-context demo --namespace=demo

## Setup API tunnel to localhost
proxy:
	@echo "Kubernetes API exposed on http://127.0.0.1:8001/"
	@kubectl proxy --address=0.0.0.0 --port 8001 || true



