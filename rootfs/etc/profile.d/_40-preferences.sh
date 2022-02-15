# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _40-preferences.sh. The leading underscore is needed to ensure this file
# executes before other files that depend on the functions defined here.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file has depends on colors.sh, geodesic-config.sh, and localhost.sh and should come after them.
# This file loads user preferences/customizations and must load before any user-visible configuration takes place.

# In case this output is being piped into a shell, print a warning message
# Specifically, this guards against:
#   docker run -it cloudposse/geodesic:latest-debian  | bash
printf 'printf "\\nIf piping Geodesic output into a shell, do not attach a terminal (-t flag)\\n" >&2; exit 8;'
# In case this output is not being piped into a shell, hide the warning message
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '                                                                                                    '
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'

# Parse the GEODESIC_TRACE variable and set the internal _GEODESIC_TRACE_CUSTOMIZATION flag if needed
if [[ $GEODESIC_TRACE =~ custom ]]; then
	export _GEODESIC_TRACE_CUSTOMIZATION=true
else
	unset _GEODESIC_TRACE_CUSTOMIZATION
fi

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_CONFIG_HOME is found to be "${GEODESIC_CONFIG_HOME:-<unset>}"

# If LOCAL_HOME is set, create a symbolic link so host pathnames (at least the ones under $HOME) work inside the shell
if [[ -n $LOCAL_HOME && ! -e $LOCAL_HOME ]]; then
	mkdir -p $(dirname "${LOCAL_HOME}") && ln -s /localhost "${LOCAL_HOME}" ||
		echo $(red Unable to create symbolic link $LOCAL_HOME '->' /localhost)
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: linked $LOCAL_HOME '->' /localhost
fi

#
# Determine the base directory for all customizations.
# We do some extra processing because GEODESIC_CONFIG_HOME needs to be set as a path in the Geodesic file system,
# but the user may have set it as a path on the host computer system. We try to accomodate that by
# searching a few other places for the directory if $GEODESIC_CONFIG_HOME does point to a valid directory
export GEODESIC_CONFIG_HOME
_GEODESIC_CONFIG_HOME_DEFAULT="/localhost/.geodesic"

if [[ -z $GEODESIC_CONFIG_HOME ]]; then
	# Not set, use default
	GEODESIC_CONFIG_HOME="${_GEODESIC_CONFIG_HOME_DEFAULT}"
elif [[ ! -d $GEODESIC_CONFIG_HOME ]]; then
	# Set, but not correctly. See if it is relative to /localhost (host ~)
	if [[ -d /localhost/$GEODESIC_CONFIG_HOME ]]; then
		GEODESIC_CONFIG_HOME="/localhost/$GEODESIC_CONFIG_HOME"
		# See if it is a full host path ending under host ~
	elif [[ -d /localhost/$(basename $GEODESIC_CONFIG_HOME) ]]; then
		GEODESIC_CONFIG_HOME="/localhost/$(basename $GEODESIC_CONFIG_HOME)"
	else
		echo $(red Invalid value of GEODESIC_CONFIG_HOME: "${GEODESIC_CONFIG_HOME}")
		echo $(red GEODESIC_CONFIG_HOME should be relative to /localhost \(normally your home directory\))
		echo $(red Using default value of ${_GEODESIC_CONFIG_HOME_DEFAULT} instead)
		GEODESIC_CONFIG_HOME="${_GEODESIC_CONFIG_HOME_DEFAULT}"
	fi
fi

if [[ ! -d $GEODESIC_CONFIG_HOME ]]; then
	if ! df -a | grep -q " ${GEODESIC_LOCALHOST:-/localhost}\$"; then
		if [[ -n $KUBERNETES_PORT ]]; then
			echo $(green Kubernetes host detected, Geodesic customization disabled.)
		else
			red "########################################################################################" >&2
			red "# No filesystem is mounted at $(bold ${GEODESIC_LOCALHOST:-/localhost}) which limits Geodesic functionality." >&2
			boot install
		fi
		export GEODESIC_CUSTOMIZATION_DISABLED="/localhost not a volume"
	elif mkdir -p $GEODESIC_CONFIG_HOME; then
		echo $(yellow Created directory "$GEODESIC_CONFIG_HOME" '(GEODESIC_CONFIG_HOME)')
	else
		echo $(red Cannot create directory "$GEODESIC_CONFIG_HOME" '(GEODESIC_CONFIG_HOME)')
	fi
fi

unset _GEODESIC_CONFIG_HOME_DEFAULT

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_CONFIG_HOME is ultimately set to "${GEODESIC_CONFIG_HOME}"
[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: HISTFILE is "${HISTFILE}" before loading preferences

function _load_geodesic_preferences() {
	local preference_list=()
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: LOADING preference files

	_search_geodesic_dirs preference_list preferences
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

unset -f _load_geodesic_preferences

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
	if [[ ! $HISTFILE =~ ^/localhost/ ]]; then
		echo "* $(yellow Not allowing \"HISTFILE=${HISTFILE}\".)"
		mkdir -p "${GEODESIC_CONFIG_HOME}/${DOCKER_IMAGE}/" && HISTFILE="${GEODESIC_CONFIG_HOME}/${DOCKER_IMAGE}/history" &&
			touch "$HISTFILE" || HISTFILE="${GEODESIC_CONFIG_HOME}/history"
		echo "* $(yellow HISTFILE forced to \"${HISTFILE}\".)"
	fi
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: HISTFILE set to "${HISTFILE}"
}
_geodesic_set_histfile
unset -f _geodesic_set_histfile
