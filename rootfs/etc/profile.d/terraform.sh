PROMPT_HOOKS+=("terraform_prompt")
function terraform_prompt() {
	shopt -s nullglob
	TF_FILES=(*.tf)
	if [ ! -z "${TF_FILES}" ]; then
		if [ ! -d ".terraform" ]; then
			echo -e "-> Run '$(green init-terraform)' to use this project"
		fi
	fi
}

# Install autocompletion rules
if [ -x '/usr/bin/terraform' ]; then
	complete -C /usr/bin/terraform terraform
fi

# Set default plugin cache dir
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/localhost/.terraform.d/plugins}"
