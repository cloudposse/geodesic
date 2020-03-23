
if command -v helm >/dev/null; then
	# Initialize auto-completion for whichever helm version is the installed default
    # Suppress error message about KUBECONFIG not found
	if [[ -r $KUBECONFIG ]]; then
		source <(helm completion bash)
	else
		source <(helm --kubeconfig /dev/null completion bash)
	fi
fi
