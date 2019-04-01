#!/usr/bin/env bash
# Allow bash to check the window size to keep prompt with relative to window size
shopt -s checkwinsize

# Cache the current screen size
export SCREEN_SIZE="${LINES}x${COLUMNS}"

# Here we install our `prompter` prompt command to run the array of PROMPT_HOOKS we set up.
# We like managing our stuff via the PROMPT_HOOKS array because it is easier to add things,
# but bash only runs the command string in PROMPT_COMMAND,
# in part because you cannot export an array or pass it to a child process.
# However, not all the utilities we use support being managed through our PROMPT_HOOKS.
# Some utilities (such as `direnv`) operate directly on the PROMPT_COMMAND variable, adding
# themselves to it. Also, the PROMPT_COMMAND is inheritied by subshells, but we will be
# running this initialization script again in the subshell.
# So we cannot just unthinkingly set PROMPT_COMMAND=prompter or PROMPT_COMMAND="${PROMPT_COMMAND};prompter"
# Instead, we examine the PROMPT_COMMAND variable, initialize it to "prompter;" if it is empty,
# or otherwise add "prompter;" to the end of the command string (inserting a ; before it if needed).
export PROMPT_COMMAND
function _install_prompter() {
	if ! [[ $PROMPT_COMMAND =~ prompter ]]; then
		local final_colon=';$'

		if [[ -z $PROMPT_COMMAND ]]; then
			PROMPT_COMMAND="prompter;"
		elif [[ $PROMPT_COMMAND =~ $final_colon ]]; then
			PROMPT_COMMAND="${PROMPT_COMMAND}prompter;"
		else
			PROMPT_COMMAND="${PROMPT_COMMAND};prompter;"
		fi
	fi
}
_install_prompter
unset -f _install_prompter

function prompter() {
	for hook in ${PROMPT_HOOKS[@]}; do
		"${hook}"
	done
}

PROMPT_HOOKS+=("reload")
function reload() {
	local current_screen_size="${LINES}x${COLUMNS}"
	# Detect changes in screensize
	if [ "${current_screen_size}" != "${SCREEN_SIZE}" ]; then
		echo "* Screen resized to ${current_screen_size}"
		export SCREEN_SIZE=${current_screen_size}
		# Instruct shell that window size has changed to ensure lines wrap correctly
		kill -WINCH $$
	fi
}

# Define our own prompt
PROMPT_HOOKS+=("geodesic_prompt")
KUBE_PS1_SYMBOL_ENABLE=${KUBE_PS1_SYMBOL_ENABLE:-false}
function geodesic_prompt() {

	case $PROMPT_STYLE in
	plain)
		# 8859-1 codepoints:
		# '\[' and '\]' are bash prompt delimiters around non-printing characters
		ASSUME_ROLE_ACTIVE_MARK="\["$(tput bold)$(tput setab 2)"\]»\["$(tput sgr0)"\] " # green
		ASSUME_ROLE_INACTIVE_MARK=$'· '
		BLACK_RIGHTWARDS_ARROWHEAD=$'=> '
		BANNER_MARK=$'§ '
		;;

	unicode)
		# unicode
		ASSUME_ROLE_ACTIVE_MARK=$'\u2705 '    # '✅'
		ASSUME_ROLE_INACTIVE_MARK=$'\u274C '  # '❌'
		BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4 ' # '➤', suggest '▶' may be present in more fonts
		BANNER_MARK=$'\u29C9 '                # '⧉'
		;;

	*)
		# default
		#	ASSUME_ROLE_ACTIVE_MARK=$' \x01'$(tput bold)$(tput setaf 2)$'\x02\u2713 \x01'$(tput sgr0)$'\x02'   # green bold '✓'
		ASSUME_ROLE_ACTIVE_MARK=$' \x01'$(tput bold)$(tput setaf 2)$'\x02\u221a \x01'$(tput sgr0)$'\x02'   # green bold '√'
		ASSUME_ROLE_INACTIVE_MARK=$' \x01'$(tput bold)$(tput setaf 1)$'\x02\u2717 \x01'$(tput sgr0)$'\x02' # red bold '✗'
		# Options for arrow per https://github.com/cloudposse/geodesic/issues/417#issuecomment-477836676
		# '»' ($'\u00bb') RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK from the Latin-1 supplement Unicode block
		# '≫' ($'\u226b') MUCH GREATER-THAN and
		# '⋙' ($'\u22d9') VERY MUCH GREATER-THAN which are from the Mathematical Operators Unicode block
		# '➤' ($'\u27a4') BLACK RIGHTWARDS ARROWHEAD from the Dingbats Unicode block
		# '▶︎' ($'\u25b6\ufe0e') BLACK RIGHT-POINTING TRIANGLE which is sometimes presented as an emoji (as GitHub likes to) '▶️'
		# '⏩︎' ($'\u23e9\ufe0e') BLACK RIGHT-POINTING DOUBLE TRIANGLE
		BLACK_RIGHTWARDS_ARROWHEAD=$'\u2a20 '                                                              # '⨠'
		BANNER_MARK='⧉ '
		;;
	esac

	if [ -n "$ASSUME_ROLE" ]; then
		STATUS=${ASSUME_ROLE_ACTIVE_MARK}
	else
		STATUS=${ASSUME_ROLE_INACTIVE_MARK}
	fi

	if [ -n "${ASSUME_ROLE}" ]; then
		ROLE_PROMPT="(${ASSUME_ROLE})"
	else
		ROLE_PROMPT="(none)"
	fi

	PS1="${STATUS}"
	PS1+="  ${ROLE_PROMPT} \W "
	PS1+=$'${GEODISIC_PROMPT_GLYPHS-$BLACK_RIGHTWARDS_ARROWHEAD}'

	if [ -n "${BANNER}" ]; then
		PS1=$' ${BANNER_MARK}'" ${BANNER} $(kube_ps1)\n"${PS1}
	fi
	export PS1
}
