# Install `direnv` via PROMPT_COMMAND hook
#

if [[ ${DIRENV_ENABLED:-true} == "true" ]]; then
	eval "$(direnv hook bash)"
fi
