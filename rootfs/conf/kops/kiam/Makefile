export CHAMBER_SERVICE ?= kops
export NAMESPACE ?= kube-system
export IAM_ROLES ?= .*

export CA_C ?= USA
export CA_ST ?= CA
export CA_L ?= Los Angeles
export CA_O ?= Cloud Posse, LLC
export CA_OU ?= Ops

# Command used to populate CFSSL configuration fields
cfssl_gen = jq ".names[0].C = env.CA_C | .names[0].ST = env.CA_ST | .names[0].L = env.CA_L | .names[0].O = env.CA_O | .names[0].OU = env.CA_OU" < $1

all: ca server agent

clean:
	rm -rf keys

deps:
	mkdir -p keys

## Intialize CA
ca: deps
	$(call cfssl_gen,ca.json) | \
		cfssl gencert -initca - | \
		cfssljson -bare keys/$@

## Generate certificate for server from CA
server: deps
	$(call cfssl_gen,$@.json) | \
		cfssl gencert -ca=keys/ca.pem -ca-key=keys/ca-key.pem - | cfssljson -bare keys/$@

## Generate certificate for agent from CA
agent: deps
	$(call cfssl_gen,$@.json) | \
		cfssl gencert -ca=keys/ca.pem -ca-key=keys/ca-key.pem - | cfssljson -bare keys/$@


## Write chamber secrets for agent
chamber/write/agent:
	chamber write $(CHAMBER_SERVICE) KIAM_AGENT_TLS_KEY `base64 -w 0 < keys/agent-key.pem`
	chamber write $(CHAMBER_SERVICE) KIAM_AGENT_TLS_CERT `base64 -w 0 < keys/agent.pem`
	chamber write $(CHAMBER_SERVICE) KIAM_AGENT_TLS_CA `base64 -w 0 < keys/ca.pem`

## Write chamber secrets for server
chamber/write/server:
	chamber write $(CHAMBER_SERVICE) KIAM_SERVER_TLS_KEY `base64 -w 0 < keys/server-key.pem`
	chamber write $(CHAMBER_SERVICE) KIAM_SERVER_TLS_CERT `base64 -w 0 < keys/server.pem`
	chamber write $(CHAMBER_SERVICE) KIAM_SERVER_TLS_CA `base64 -w 0 < keys/ca.pem` 

## Apply default annotation to namespace for permitted roles
annotate:
	kubectl annotate --overwrite namespace $(NAMESPACE) "iam.amazonaws.com/permitted=$(IAM_ROLES)"
