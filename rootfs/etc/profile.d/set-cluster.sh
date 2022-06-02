#!/bin/bash

# Usage:
#   set-cluster <cluster-short-name>|off
#
#   With <cluster-short-name> updates the kubecfg file for the cluster with that short name (e.g. "corp")
#   and updates KUBECONFIG to point to that file.

#   With "off", deletes the currently active kubecfg file and unsets KUBECONFIG
#

function _update_cluster_config() {
	local new_config=
	new_config=$(eks-update-kubeconfig set-kubeconfig "$@") || return

	local current_namespace
	local set_namespace=1

	current_namespace=$(KUBECONFIG="$new_config" kubens -c 2>/dev/null)
	set_namespace=$?
	if ! KUBECONFIG="$new_config" kubectl auth can-i -Aq create selfsubjectaccessreviews.authorization.k8s.io >/dev/null 2>&1 </dev/null; then
		eks-update-kubeconfig "$@" || return
	fi
	export KUBECONFIG="$new_config"
	(($(kubectx | wc -l) > 1)) && kubectx "$(kubectx | grep "${1}-eks-cluster" | head -1)"
	(($set_namespace == 0)) && kubens "$current_namespace"
}

function set-cluster() {
	KUBECONFIG_DIR=$(dirname ${KUBECONFIG:-/dev/shm/kubecfg})
	if [[ $1 == "off" ]]; then
		eks-update-kubeconfig off && unset KUBECONFIG
		return 0
	fi

	local cluster=$1
	shift 1
	if [[ $cluster =~ ^[a-z]+$ ]]; then
		AWS_REGION_ABBREVIATION_TYPE=${AWS_REGION_ABBREVIATION_TYPE:-fixed}
		AWS_DEFAULT_SHORT_REGION=${AWS_DEFAULT_SHORT_REGION:-$(aws-region --${AWS_REGION_ABBREVIATION_TYPE} ${AWS_DEFAULT_REGION:-us-west-2})}
		_update_cluster_config ${AWS_DEFAULT_SHORT_REGION}-$cluster "$@"
	else
		_update_cluster_config $cluster "$@"
	fi
}
