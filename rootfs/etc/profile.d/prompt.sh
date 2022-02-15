#!/bin/bash
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
# We do not want subshells to try to run prompt commands if they are not defined, so we do not export PROMPT_COMMAND
export -n PROMPT_COMMAND
# We do not want our dynamic prompt to be copied and not updated in a subshell, so we do not export PS1, either
export -n PS1
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
	# Color escapes: 1=red, 2=green, 3=yellow, 6=cyan
	plain)
		# 8859-1 codepoints:
		# '\[' and '\]' are bash prompt delimiters around non-printing characters
		[[ -z $ASSUME_ROLE_ACTIVE_MARK ]] && ASSUME_ROLE_ACTIVE_MARK="\["$(tput bold)$(tput setab 2)"\]»\["$(tput sgr0)"\]" # green
		[[ -z $ASSUME_ROLE_INACTIVE_MARK ]] && ASSUME_ROLE_INACTIVE_MARK=$'·'
		[[ -z $BLACK_RIGHTWARDS_ARROWHEAD ]] && BLACK_RIGHTWARDS_ARROWHEAD=$'=>'
		[[ -z $BANNER_MARK ]] && BANNER_MARK=$'§'
		;;

	unicode)
		# unicode
		[[ -z $ASSUME_ROLE_ACTIVE_MARK ]] && ASSUME_ROLE_ACTIVE_MARK=$'\u2705'       # '✅'
		[[ -z $ASSUME_ROLE_INACTIVE_MARK ]] && ASSUME_ROLE_INACTIVE_MARK=$'\u274C'   # '❌'
		[[ -z $BLACK_RIGHTWARDS_ARROWHEAD ]] && BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4' # '➤', suggest '▶' may be present in more fonts
		[[ -z $BANNER_MARK ]] && BANNER_MARK=$'\u29C9'                               # '⧉'
		;;

	fancy)
		# Same as default, except for BLACK_RIGHTWARDS_ARROWHEAD, because the character used in the
		# default set, Z NOTATION SCHEMA PIPING, is from the "Supplemental Mathematical Operators" Unicode block
		# which is not included by default in the Ubuntu terminal font.
		# See https://github.com/cloudposse/geodesic/issues/417
		[[ -z $ASSUME_ROLE_ACTIVE_MARK ]] && ASSUME_ROLE_ACTIVE_MARK=$'\x01'$(tput bold)$(tput setaf 2)$'\x02\u221a\x01'$(tput sgr0)$'\x02'     # green bold '√'
		[[ -z $ASSUME_ROLE_INACTIVE_MARK ]] && ASSUME_ROLE_INACTIVE_MARK=$'\x01'$(tput bold)$(tput setaf 1)$'\x02\u2717\x01'$(tput sgr0)$'\x02' # red bold '✗'
		[[ -z $BLACK_RIGHTWARDS_ARROWHEAD ]] && BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4'                                                            # '➤'
		[[ -z $BANNER_MARK ]] && BANNER_MARK='⧉'                                                                                                # \u29c9 TWO JOINED SQUARES
		;;

	*)
		# default
		#	ASSUME_ROLE_ACTIVE_MARK=$'\x01'$(tput bold)$(tput setaf 2)$'\x02\u2713\x01'$(tput sgr0)$'\x02'   # green bold '✓'
		[[ -z $ASSUME_ROLE_ACTIVE_MARK ]] && ASSUME_ROLE_ACTIVE_MARK=$'\x01'$(tput bold)$(tput setaf 2)$'\x02\u221a\x01'$(tput sgr0)$'\x02'     # green bold '√'
		[[ -z $ASSUME_ROLE_INACTIVE_MARK ]] && ASSUME_ROLE_INACTIVE_MARK=$'\x01'$(tput bold)$(tput setaf 1)$'\x02\u2717\x01'$(tput sgr0)$'\x02' # red bold '✗'
		# Options for arrow per https://github.com/cloudposse/geodesic/issues/417#issuecomment-477836676
		# '»' ($'\u00bb') RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK from the Latin-1 supplement Unicode block
		# '≫' ($'\u226b') MUCH GREATER-THAN and
		# '⋙' ($'\u22d9') VERY MUCH GREATER-THAN which are from the Mathematical Operators Unicode block
		# '➤' ($'\u27a4') BLACK RIGHTWARDS ARROWHEAD from the Dingbats Unicode block
		# '▶︎' ($'\u25b6\ufe0e') BLACK RIGHT-POINTING TRIANGLE which is sometimes presented as an emoji (as GitHub likes to) '▶️'
		# '⏩︎' ($'\u23e9\ufe0e') BLACK RIGHT-POINTING DOUBLE TRIANGLE
		[[ -z $BLACK_RIGHTWARDS_ARROWHEAD ]] && BLACK_RIGHTWARDS_ARROWHEAD=$'\u2a20' # '⨠' Z NOTATION SCHEMA PIPING
		[[ -z $BANNER_MARK ]] && BANNER_MARK='⧉'                                     # \u29c9 TWO JOINED SQUARES
		;;
	esac

	# "(HOST)" with "HOST" in bold red. Only test for unset ("-") instead of unset or null (":-") so that
	# the feature can be suppressed by setting PROMPT_HOST_MARK to null.
	[[ -z $PROMPT_HOST_MARK ]] && PROMPT_HOST_MARK="${PROMPT_HOST_MARK-$'(\x01'$(tput bold)$(tput setaf 1)$'\x02HOST\x01'$(tput sgr0)$'\x02)'}"

	local level_prompt
	case $SHLVL in
	1) level_prompt='.' ;;
	2) level_prompt=':' ;;
	3) level_prompt='⋮' ;; # vertical elipsis \u22ee from Mathematical Symbols
	*) level_prompt="$SHLVL" ;;
	esac
	level_prompt=$'\x01'$(tput bold)$'\x02'"${level_prompt}"$'\x01'$(tput sgr0)$'\x02'

	if [ -n "$ASSUME_ROLE" ]; then
		STATUS=${ASSUME_ROLE_ACTIVE_MARK}
		ROLE_PROMPT="[${ASSUME_ROLE}]"
	else
		STATUS=${ASSUME_ROLE_INACTIVE_MARK}
		ROLE_PROMPT="[none]"
	fi

	local secrets_active=""
	local secrets="${PROMPT_SECRET_ENVS:-GITHUB_TOKEN;KOPS_SSH_PRIVATE_KEY}"
	for secret_name in $(echo "$secrets" | tr ';' ' '); do
		if [[ -z $secret_name ]] || ! local -n ref=$secret_name; then
			echo $(red Error parsing PROMPT_SECRET_ENVS \'"${PROMPT_SECRET_ENVS}"\')
			break
		fi
		if [[ -n $ref ]]; then
			secrets_active="+"
			break
		fi
	done

	local dir_prompt
	dir_prompt=" ${STATUS} ${level_prompt} "
	if [[ -n $PROMPT_HOST_MARK ]] && file_on_host "$(pwd -P)"; then
		dir_prompt+="${ROLE_PROMPT} ${PROMPT_HOST_MARK} \W "
	else
		dir_prompt+="${ROLE_PROMPT} \W "
	fi
	dir_prompt+=$'${GEODESIC_PROMPT_GLYPHS-${BLACK_RIGHTWARDS_ARROWHEAD} }'

	update_terraform_prompt
	local old_kube_ps1_prefix="$KUBE_PS1_PREFIX"
	KUBE_PS1_PREFIX="("
	local tf_prompt
	if [[ $GEODESIC_TF_PROMPT_ACTIVE == "true" ]]; then
		local tf_mark
		if [[ $GEODESIC_TF_PROMPT_TF_NEEDS_INIT == "true" ]]; then
			tf_mark="${ASSUME_ROLE_INACTIVE_MARK}"
		else
			tf_mark="${ASSUME_ROLE_ACTIVE_MARK}"
		fi
		if [[ -n ${GEODESIC_TF_PROMPT_LINE} ]]; then
			tf_prompt=" ${tf_mark} ${GEODESIC_TF_PROMPT_LINE}\n"
		fi
		if [[ $GEODESIC_TERRAFORM_WORKSPACE_PROMPT_ENABLED == "true" ]]; then
			KUBE_PS1_PREFIX="$(yellow "cluster:")("
		fi
	fi
	if [[ $old_kube_ps1_prefix != $KUBE_PS1_PREFIX ]]; then
		KUBE_PS1_KUBECONFIG_CACHE=""
	fi

	if [ -n "${BANNER}" ]; then
		# Intentional 2 spaces between banner mark and banner in order to offset it from level prompt
		PS1=$' ${BANNER_MARK}'"  ${BANNER} $(kube_ps1)${secrets_active}\n${tf_prompt}${dir_prompt}"
	else
		PS1="${tf_prompt}${dir_prompt}"
	fi
}
