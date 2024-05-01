function update_terraform_prompt() {
	if [[ ${GEODESIC_TF_PROMPT_ENABLED:-false} == "true" ]]; then
		# Test if there are any files with names ending in ".tf"
		if compgen -G '*.tf' >/dev/null; then
			export GEODESIC_TF_PROMPT_ACTIVE=true
			local terraform_workspace=$(terraform workspace show)
			if [ "$terraform_workspace" == "default" ]; then
				if [[ -d ${TF_DATA_DIR:-.terraform} ]]; then
					export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
				else
					export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=true
				fi
				export GEODESIC_TF_PROMPT_LINE=" terraform workspace:{$(red-n default)}"
			else
				export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
				export GEODESIC_TF_PROMPT_LINE=" terraform workspace:{$(green-n "$terraform_workspace")}"
			fi
		else
			export GEODESIC_TF_PROMPT_ACTIVE=false
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
