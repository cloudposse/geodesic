#!/usr/bin/env bash
# Allow bash to check the window size to keep prompt with relative to window size
shopt -s checkwinsize

# Cache the current screen size
export SCREEN_SIZE="${LINES}x${COLUMNS}"

export PROMPT_COMMAND=prompter
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
function geodesic_prompt() {

	case $PROMPT_STYLE in
	plain)
		# 8859-1 codepoints:
		ASSUME_ROLE_ACTIVE_MARK=$(tput bold)$(tput setab 2)$'»'$(tput sgr0)' ' # green
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
		ASSUME_ROLE_ACTIVE_MARK=$' \x01'$(tput bold)$(tput setaf 2)$'\x02\u2713 \x01'$(tput sgr0)$'\x02'   # green bold '✓'
		ASSUME_ROLE_INACTIVE_MARK=$' \x01'$(tput bold)$(tput setaf 1)$'\x02\u2717 \x01'$(tput sgr0)$'\x02' # red bold '✗'
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

	PS1=$'${STATUS}'
	PS1+="  ${ROLE_PROMPT} \W "
	PS1+=$'${BLACK_RIGHTWARDS_ARROWHEAD} '

	if [ -n "${BANNER}" ]; then
		PS1=$' ${BANNER_MARK}'" ${BANNER} $(kube_ps1)\n"${PS1}
	fi
	export PS1
}
