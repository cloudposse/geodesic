function update_terraform_prompt() {
	[[ ${GEODESIC_TF_PROMPT_ENABLED:-false} == "true" ]] || return 0
	# Test if there are any files with names ending in ".tf"
	if compgen -G '*.tf' >/dev/null; then
		export GEODESIC_TF_PROMPT_ACTIVE=true
		if [[ $GEODESIC_TERRAFORM_WORKSPACE_PROMPT_ENABLED != "true" ]]; then
			if [ ! -d ".terraform" ]; then
				export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=true
				export GEODESIC_TF_PROMPT_LINE=" -> Run '$(green init-terraform)' to use this project"
			else
				export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
				export GEODESIC_TF_PROMPT_LINE=""
			fi
		else
			local terraform_workspace=$(terraform workspace show)
			if [ "$terraform_workspace" == "default" ]; then
				export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=true
				export GEODESIC_TF_PROMPT_LINE=" -> terraform workspace '$(red "$terraform_workspace")'. Use '$(yellow make workspace/...)' to switch terraform workspaces"
			else
				export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
				export GEODESIC_TF_PROMPT_LINE=" workspace:{"$'\x01'$(tput setaf 2)$'\x02'"$terraform_workspace"$'\x01'$(tput sgr0)$'\x02'"}"
			fi
		fi
	else
		export GEODESIC_TF_PROMPT_ACTIVE=false
	fi
}

# Install auto-completion rules
if which terraform >/dev/null; then
	complete -C "$(which terraform)" terraform
fi

for tf in /usr/bin/terraform-*; do
	[[ -x $tf ]] && complete -C $tf $(basename $tf)
done

# Set default plugin cache dir (must not be one of the mirror directories)
# https://www.terraform.io/docs/commands/cli-config.html#implied-local-mirror-directories)
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/localhost/.terraform.d/plugin-cache}"
