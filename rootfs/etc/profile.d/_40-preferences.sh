# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _40-preferences.sh. The leading underscore is needed to ensure this file
# executes before other files that depend on the functions defined here.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file depends on colors.sh, geodesic-config.sh, and localhost.sh and should come after them.
# This file loads user preferences/customizations and must load before any user-visible configuration takes place.

# Parse the GEODESIC_TRACE variable and set the internal _GEODESIC_TRACE_CUSTOMIZATION flag if needed
if [[ $GEODESIC_TRACE =~ custom ]]; then
	export _GEODESIC_TRACE_CUSTOMIZATION=true
else
	unset _GEODESIC_TRACE_CUSTOMIZATION
fi

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_CONFIG_HOME is found to be "${GEODESIC_CONFIG_HOME:-<unset>}"

#
# Determine the base directory for all customizations.
# We do some extra processing because GEODESIC_CONFIG_HOME needs to be set as a path in the Geodesic file system,
# but the user may have set it as a path on the host computer system. We try to accomodate that by
# searching a few other places for the directory if $GEODESIC_CONFIG_HOME does point to a valid directory
export GEODESIC_CONFIG_HOME
_GEODESIC_CONFIG_HOME_DEFAULT="/root/.config/geodesic"

if [[ -z $GEODESIC_CONFIG_HOME ]]; then
	# Not set, use default
	GEODESIC_CONFIG_HOME="${_GEODESIC_CONFIG_HOME_DEFAULT}"
elif [[ ! -d $GEODESIC_CONFIG_HOME ]]; then
	if [[ -n $KUBERNETES_PORT ]]; then
		green "# Kubernetes host detected, Geodesic customization disabled."
		export GEODESIC_CUSTOMIZATION_DISABLED="No config dir and Kubernetes detected"
	else
		red "# GEODESIC_CONFIG_HOME is set to a non-existent directory: ${GEODESIC_CONFIG_HOME}" >&2
		red "# No Geodesic configuration will be loaded." >&2
	fi
	mkdir -p "${GEODESIC_CONFIG_HOME}"
fi

function _term_fold() {
	local cols
	cols=$(tput cols 2>/dev/null || echo "80")
	[ -z "$cols" ] || [ "$cols" = "0" ] && cols=80
	fold -w "$cols" -s
}

[[ -n ${WORKSPACE_MOUNT} ]] || export WORKSPACE_MOUNT=/workspace
if ! findmnt "${WORKSPACE_MOUNT}" >/dev/null 2>&1; then
	# Keep the lines short, because some terminals will truncate them rather than wrap them,
	# which causes important information to be lost.
	red "############################################################" >&2
	red "# No filesystem is mounted at $(bold "${WORKSPACE_MOUNT}")" | _term_fold >&2
	red "# which limits Geodesic functionality." | _term_fold >&2
	boot install
elif [[ -z $(find "${WORKSPACE_MOUNT}" -mindepth 1 -maxdepth 1) ]]; then
	red "################################################################" >&2
	red "# No files found under $(bold "${WORKSPACE_MOUNT}")." | _term_fold >&2
	red "# Run Geodesic from your source directory." | _term_fold >&2
	red "# Change (\`cd\`) to your source directory (in your git repo)" | _term_fold >&2
	red "# and run ${APP_NAME:-Geodesic} from there." | _term_fold >&2
	red "################################################################" >&2
	echo
fi

unset _GEODESIC_CONFIG_HOME_DEFAULT

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_CONFIG_HOME is ultimately set to "${GEODESIC_CONFIG_HOME}"
[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: HISTFILE is "${HISTFILE}" before loading preferences

function _load_geodesic_preferences() {
	local preference_list=()
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: LOADING preference files

	_search_geodesic_dirs preference_list preferences
	local file
	for file in "${preference_list[@]}"; do
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: loading preference file "$file"
		source "$file"
	done
}

if [[ ${GEODESIC_CUSTOMIZATION_DISABLED-false} != false ]]; then
	echo $(red Disabling user customizations: GEODESIC_CUSTOMIZATION_DISABLED is \'"${GEODESIC_CUSTOMIZATION_DISABLED}"\')
else
	_load_geodesic_preferences
fi

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] || unset -f _load_geodesic_preferences

## Append rather than overwrite history file
shopt -s histappend

## Default to saving 2500 lines of history rather than the bash default of 500
HISTFILESIZE="${HISTFILESIZE:-2500}"

# Search for and find the history file most specifically targeted to this DOCKER_IMAGE
function _geodesic_set_histfile() {
	## Save shell history in the most specific place
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: HISTFILE is "${HISTFILE}" after loading preferences
	[[ $HISTFILE == ${HOME}/.bash_history ]] && unset HISTFILE
	local histfile_list=(${HISTFILE:-${GEODESIC_CONFIG_HOME}/history})
	_search_geodesic_dirs histfile_list history
	export HISTFILE="${histfile_list[-1]}"
	[[ -n $HISTFILE ]] || HISTFILE="${GEODESIC_CONFIG_HOME}/history"
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo 'trace: HISTFILE set to "'"${HISTFILE}"'"'
}
_geodesic_set_histfile

[[ $GEODESIC_TRACE =~ hist ]] || unset -f _geodesic_set_histfile
