# Kiam

The `kiam` service requires TLS certificates to secure communitcation between agent and server.

## Quickstart

Run `make all` to generate CA, server and agent certificates. All keys are written to `keys/`.
Run `make chamber/write/agent` to write agent secrets. All keys are read from `keys/`.
Run `make chamber/write/server` to write server secrets. All keys are read from `keys/`.

## Troubleshooting

<https://github.com/uswitch/kiam/issues/94> 

```
GRPC_GO_LOG_SEVERITY_LEVEL=info GRPC_GO_LOG_VERBOSITY_LEVEL=8 /health --cert=/etc/kiam/tls/cert --key=/etc/kiam/tls/key --ca=/etc/kiam/tls/ca --server-address=
localhost:443
```

