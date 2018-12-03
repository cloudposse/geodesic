PROMPT_HOOKS+=("direnv_prompt")

function direnv_prompt() {
	eval "$(direnv hook bash)"
}
