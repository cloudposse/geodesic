PROMPT_HOOKS+=("kube_ps1_cache_buster")
function kube_ps1_cache_buster() {
	# If config cache is empty
	if [ -z "${KUBE_PS1_KUBECONFIG_CACHE}" ]; then
		# And we have a config
		if [ -f "${KUBECONFIG}" ]; then
			# Then turn on the prompt
			kubeon
			_kube_ps1_get_context_ns
		fi
	else
		# Config cache is not empty, but the file doesn't exist
		if [ ! -f "${KUBE_PS1_KUBECONFIG_CACHE}" ]; then
			# Then turn off the prompt
			unset KUBE_PS1_KUBECONFIG_CACHE
			kubeoff
			_kube_ps1_get_context_ns
		fi
	fi
}
