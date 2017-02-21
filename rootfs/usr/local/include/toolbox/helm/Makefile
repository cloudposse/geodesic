include helpers
include all

## Init the client & server
init:
	@helm init

## Init the helm client
init-client:
	@helm init --client-only

## Init the repositories
init-repos:
	@helm repo add cloudposse-stable https://charts.cloudposse.com/stable
	@helm repo add cloudposse-incubator https://charts.cloudposse.com/incubator

## Update repo indexes
update:
	@helm repo update

## Upgrade tiller
upgrade:
	@helm init --upgrade

## Manage charts
chart: module
