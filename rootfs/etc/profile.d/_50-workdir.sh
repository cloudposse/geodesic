# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _50-workdir.sh. The leading underscore is needed to ensure this file
# executes before other files that may depend on it.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file depends on colors.sh, localhost.sh, and preferences,sh and must come after them
#

# Outputs the device the file resides on, or /dev/null if the file does not exist
function _file_device() {
	{ [[ -e $1 ]] && df --output=source "$1" | tail -1; } || echo '/dev/null'
}

# file_on_host is true when the argument is a file or directory that appears to be on the Host file system.
# Intended to support files on user-defined bind mounts in addition to `/localhost`.
# This function is run by the command line prompt setup, so it should be very fast.
# Therefore we cache some info in the environment.
if [[ $GEODESIC_LOCALHOST_DEVICE == "disabled" ]]; then
	red "# Host filesystem device detection disabled."
elif df -a | grep -q " ${GEODESIC_LOCALHOST:-/localhost}\$"; then
	export GEODESIC_LOCALHOST_DEVICE=$(_file_device "${GEODESIC_LOCALHOST:-/localhost}")
	if [[ $GEODESIC_LOCALHOST_DEVICE == $(_file_device /) ]]; then
		red "# Host filesystem device detection failed. Falling back to \"path starts with /localhost\"."
		GEODESIC_LOCALHOST_DEVICE="same-as-root"
	fi
else
	export GEODESIC_LOCALHOST_DEVICE="missing"
fi

function file_on_host() {
	if [[ $GEODESIC_LOCALHOST_DEVICE =~ ^(disabled|missing)$ ]]; then
		return 1
	elif [[ $GEODESIC_LOCALHOST_DEVICE == "same-as-root" ]]; then
		[[ $(readlink -e "$1") =~ ^/localhost ]]
	else
		local dev="$(_file_device "$1")"
		[[ $dev == $GEODESIC_LOCALHOST_DEVICE ]] || [[ $dev == $GEODESIC_LOCALHOST_MAPPED_DEVICE ]]
	fi
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
		if [[ -n $LOCAL_HOME ]] && { [[ $GEODESIC_LOCALHOST_DEVICE == "disabled" ]] || file_on_host "$GEODESIC_HOST_CWD"; }; then
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
