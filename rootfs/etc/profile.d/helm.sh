if command -v helm >/dev/null; then
	# Initialize auto-completion for whichever helm version is the installed default
	# Suppress error message about KUBECONFIG not found or being world readable
	if [[ -r $KUBECONFIG ]]; then
		chmod 600 $KUBECONFIG
		source <(helm completion bash)
	else
		touch /tmp/kubecfg
		chmod 600 /tmp/kubecfg
		source <(helm --kubeconfig /tmp/kubecfg completion bash)
		rm -f /tmp/kubecfg
	fi
fi
