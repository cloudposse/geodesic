## Perform any clean-up or post-setup actions

# Set up command completion for command aliases

_install_alias_completion

# remove duplicates from PROMPT_COMMAND
function _dedupe_prompt_command() {
	local prompt_command=( ${PROMPT_COMMAND//;/ } )
	PROMPT_COMMAND=

	for cmd in "${prompt_command[@]}"; do
		[[ $PROMPT_COMMAND =~ $cmd ]] || PROMPT_COMMAND="${PROMPT_COMMAND}$cmd;"
	done
}

_dedupe_prompt_command
