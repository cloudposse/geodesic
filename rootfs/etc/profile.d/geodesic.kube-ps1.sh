# A little extra help for https://github.com/jonmosco/kube-ps1
PROMPT_HOOKS+=("kube_ps1_helper")
# kube-ps1 v0.7.0 is better about detecting changes,
# so we can ease up on the help. Also, setting KUBE_PS1_CONTEXT to an
# empty string hides the prompt without disabling it, so we use that
# rather than kubeoff so we do not have to detect when to run kubeon
function kube_ps1_helper() {
	# HACK for kube-ps1 v0.7.0 to hide kube prompt if no cluster is configured
	# This will probably be a supported option in v0.8.0 but this is the cheapest
	# solution for now.
	# https://github.com/jonmosco/kube-ps1/issues/115
	if [[ $KUBE_PS1_CONTEXT == "N/A" ]]; then
		KUBE_PS1_CONTEXT=""
	fi

	# Update the prompt if the kubecfg file is deleted.
	# https://github.com/jonmosco/kube-ps1/issues/118
	if [[ -n $KUBE_PS1_CONTEXT ]] && [[ ! -r "${KUBECONFIG}" ]]; then
		KUBE_PS1_CONTEXT=""
	fi
}

# This shortens the cluster name of EKS clusters.
# It should not affect other cluster names, so should be safe as default.
# Users can override it if they want to.
function short_cluster_name_from_eks() {
	# If it is not a cluster ARN, leave it alone
	if ! [[ $1 =~ ^arn:.*:cluster/ ]]; then
		printf "%s" "$1"
		return 0
	fi
	local full_name=$(printf "%s" "$1" | cut -d/ -f2)
	# remove namespace prefix if present
	full_name=${full_name#${NAMESPACE}-}
	# remove eks and everything after it, if present
	full_name=${full_name%-eks-*}
	printf "%s" "${full_name}"
	# If NAMESPACE is unset, delete everything before and including the first dash
	# printf "%s" "$1" | sed -e 's%arn.*:cluster/'"${NAMESPACE:-[^-]\+}"'-\([^-]\+\)-eks-.*$%\1%'
}
[[ -z $KUBE_PS1_CLUSTER_FUNCTION ]] && KUBE_PS1_CLUSTER_FUNCTION=short_cluster_name_from_eks
