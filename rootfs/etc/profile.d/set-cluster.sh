#!/bin/bash

# Usage:
#   set-cluster <cluster-short-name>|off
#
#   With <cluster-short-name> updates the kubecfg file for the cluster with that short name (e.g. "corp")
#   and updates KUBECONFIG to point ot that file.

#   With "off", deletes the currently active kubecfg file and unsets KUBECONFIG
#

function _update_cluster_config() {
	local new_config=$(eks-update-kubeconfig set-kubeconfig "$@")
	local current_namespace
	local set_namespace=1

	current_namespace=$(KUBECONFIG="$new_config"kubens -c 2>/dev/null)
	set_namespace=$?
	if ! KUBECONFIG="$new_config" kubectl auth can-i -Aq create selfsubjectaccessreviews.authorization.k8s.io 2>/dev/null; then
		eks-update-kubeconfig "$@"
	fi
	export KUBECONFIG="$new_config"
	(($set_namespace == 0)) && kubens "$current_namespace"
}

function set-cluster() {
	KUBECONFIG_DIR=$(dirname ${KUBECONFIG:-/dev/shm/kubecfg})
	if [[ $1 == "off" ]]; then
		eks-update-kubeconfig "$@" && unset KUBECONFIG
	else
		_update_cluster_config "$@"
	fi
}
