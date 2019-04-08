PROMPT_HOOKS+=("terraform_prompt")
function terraform_prompt() {
	# Test if there are any files with names ending in ".tf"
	if compgen -G '*.tf' >/dev/null; then
		if [ ! -d ".terraform" ]; then
			echo -e "-> Run '$(green init-terraform)' to use this project"
		fi
	fi
}

# Install auto-completion rules
if which terraform >/dev/null; then
	complete -C "$(which terraform)" terraform
fi

# Set default plugin cache dir
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/localhost/.terraform.d/plugins}"
