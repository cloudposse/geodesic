# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file sets the working directory inside Geodesic to match the host directory Geodesic
# was launched from, if possible. If the host directory is not accessible, it sets the working directory to `/`.
#
# This file is named _workdir.sh. The leading underscore is needed to ensure this file executes before
# other files that may depend on it. The "w" is needed to ensure it is loaded *after* _preferences.sh
#

function _file_device() {
	df --output=source "$1" | tail -1
}

# file_on_host is true when the argument is a file or directory that appears to be on the Host file system.
# Intended to support files on user-defined bind mounts in addition to `/localhost`.
# This function is run by the command line prompt setup, so it should be very fast.
# Therefore we cache some info in the environment.
if df -a | grep -q /localhost; then
	export GEODESIC_LOCALHOST_DEVICE=$(_file_device /localhost)
else
	export GEODESIC_LOCALHOST_MISSING=true
fi

function file_on_host() {
  [[ $GEODESIC_LOCALHOST_MISSING != "true" ]] && [[  $(_file_device "$1") == ${GEODESIC_LOCALHOST_DEVICE} ]]
}

function _default_initial_wd() {
	if [[ -d /stacks ]]; then
		# Newer default using `atmos` and stacks
		export GEODESIC_WORKDIR="/"
	else
		# Older default working directory
		export GEODESIC_WORKDIR="/conf"
	fi
	red "# Defaulting initial working directory to \"${GEODESIC_WORKDIR}\""
}

# You can set GEODESIC_WORKDIR in your Geodesic preferences to have full control of your starting working directory
if [[ -d $GEODESIC_WORKDIR ]]; then
	[[ $SHLVL == 1 ]] && green "# Initial working directory configured as ${GEODESIC_WORKDIR}"
else
	if [[ -d $GEODESIC_HOST_CWD ]]; then
		if [[ -n $LOCAL_HOME ]] && $(file_on_host "$GEODESIC_HOST_CWD"); then
			export GEODESIC_WORKDIR=$(readlink -e "${GEODESIC_HOST_CWD}")
			green "# Initial working directory set from host CWD to ${GEODESIC_WORKDIR}"
		else
			red "# Host CWD \"${GEODESIC_HOST_CWD}\" does not appear to be accessible from this container"
			_default_initial_wd
		fi
	else
		red "# No configured working directory is accessible:"
		red "#    GEODESIC_WORKDIR is \"$GEODESIC_WORKDIR\""
		red "#    GEODESIC_HOST_CWD is \"$GEODESIC_HOST_CWD\""
		_default_initial_wd
	fi
fi

[[ $SHLVL == 1 ]] && cd "${GEODESIC_WORKDIR}"

unset -f _default_initial_wd
