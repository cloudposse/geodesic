#!/bin/bash

# Usage:
#   set-cluster <cluster-short-name>|off
#
#   With <cluster-short-name> updates the kubecfg file for the cluster with that short name (e.g. "corp")
#   and updates KUBECONFIG to point ot that file.

#   With "off", deletes the currently active kubecfg file and unsets KUBECONFIG
#

function set-cluster() {
	KUBECONFIG_DIR=$(dirname ${KUBECONFIG:-/dev/shm/kubecfg})
	export EKS_KUBECONFIG_PATTERN="${EKS_KUBECONFIG_PATTERN:-${KUBECONFIG_DIR}/kubecfg.%s}"
	if [[ $1 == "off" ]]; then
		eks-update-kubeconfig "$@" && unset KUBECONFIG
	else
		eks-update-kubeconfig "$@" && export KUBECONFIG=$(printf "$EKS_KUBECONFIG_PATTERN" $1)
	fi
}
