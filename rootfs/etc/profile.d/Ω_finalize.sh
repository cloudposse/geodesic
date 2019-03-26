# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named Ω_finalize.sh. The leading Ω (Capital Greek Omega) is needed to ensure this file executes after
# other files that this function needs to be able to see.
# This file should come next to last, followed only by Ω_overrides.sh.

## Perform any clean-up or post-setup actions

# Set up command completion for command aliases.
# This requires that all commands and command completions are installed, and also that all aliases are defined.

_install_alias_completion

# Remove duplicates from PROMPT_COMMAND
# This is only effective if all commands that modify the PROMPT_COMMAND variable have already executed.
function _dedupe_prompt_command() {
	local prompt_command=(${PROMPT_COMMAND//;/ })
	PROMPT_COMMAND=

	for cmd in "${prompt_command[@]}"; do
		[[ $PROMPT_COMMAND =~ $cmd ]] || PROMPT_COMMAND="${PROMPT_COMMAND}$cmd;"
	done
}

_dedupe_prompt_command
