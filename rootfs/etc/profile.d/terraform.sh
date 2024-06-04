if command -v terraform >/dev/null || command -v tofu >/dev/null; then
	if command -v terraform >/dev/null; then
		export GEODESIC_TF_CMD=${GEODESIC_TF_CMD:-terraform}
	else
		export GEODESIC_TF_CMD=tofu
	fi
	function _update_terraform_prompt() {
		if [[ ${GEODESIC_TF_PROMPT_ENABLED:-false} == "true" ]]; then
			# Test if there are any files with names ending in ".tf"
			if compgen -G '*.tf' >/dev/null; then
				export GEODESIC_TF_PROMPT_ACTIVE=true
				local terraform_workspace=$($GEODESIC_TF_CMD workspace show)
				if [ "$terraform_workspace" == "default" ]; then
					if [[ -d ${TF_DATA_DIR:-.terraform} ]]; then
						export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
					else
						export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=true
					fi
					export GEODESIC_TF_PROMPT_LINE=" ${GEODESIC_TF_CMD} workspace:{$(red-n default)}"
				else
					export GEODESIC_TF_PROMPT_TF_NEEDS_INIT=false
					export GEODESIC_TF_PROMPT_LINE=" ${GEODESIC_TF_CMD} workspace:{$(green-n "$terraform_workspace")}"
				fi
			else
				export GEODESIC_TF_PROMPT_ACTIVE=false
			fi
		else
			export GEODESIC_TF_PROMPT_ACTIVE=false
		fi
	}
else
	function _update_terraform_prompt() { :; }
fi

# Install auto-completion rules
if command -v tofu >/dev/null; then
	complete -C "$(command -v tofu)" tofu
fi

if command -v terraform >/dev/null; then
	complete -C "$(command -v terraform)" terraform
fi

for tf in /usr/bin/terraform-*; do
	[[ -x $tf ]] && complete -C $tf $(basename $tf)
done

# Set default plugin cache dir (must not be one of the mirror directories)
# https://www.terraform.io/docs/commands/cli-config.html#implied-local-mirror-directories)
export TF_PLUGIN_CACHE_DIR="${TF_PLUGIN_CACHE_DIR:-/localhost/.terraform.d/plugin-cache}"
mkdir -p "$TF_PLUGIN_CACHE_DIR" || unset TF_PLUGIN_CACHE_DIR
