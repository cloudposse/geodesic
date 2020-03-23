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
	[[ $KUBE_PS1_CONTEXT == "N/A" ]] && KUBE_PS1_CONTEXT=""

    # Update the prompt if the kubecfg file is deleted.
	# https://github.com/jonmosco/kube-ps1/issues/118
	[[ -n $KUBE_PS1_CONTEXT ]] && [[ ! -r  "${KUBECONFIG}" ]] && KUBE_PS1_CONTEXT=""

}


# This shortens the cluster name based on our EKS cluster naming pattern,
# taking just the characters between the first and second dashes after "cluster/".
# It should not affect other cluster names, so should be safe as default.
function short_cluster_name_from_eks() {
	printf "%s" "$1" | sed -e 's%arn.*:cluster/[^-]\+-\([^-]\+\)-.*$%\1%'
}
KUBE_PS1_CLUSTER_FUNCTION=short_cluster_name_from_eks
