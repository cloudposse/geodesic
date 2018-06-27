# Kiam

The `kiam` service requires TLS certificates to secure communitcation between agent and server.

## Quickstart

Run `make all` to generate CA, server and agent certificates. All keys are written to `keys/`.
Run `make chamber/write/agent` to write agent secrets. All keys are read from `keys/`.
Run `make chamber/write/server` to write server secrets. All keys are read from `keys/`.

