# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _30-geodesic-config.sh. The leading underscore is needed to ensure this file
# executes before other files that depend on the functions defined here.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file defines functions but does not execute them, so it can come anywhere
# before the first script to use one of its functions, such as preferences.sh.

# bash functions that support the user customization framework
#
# Given the name of a resource, _search_geodesic_dirs assembles an array of matching, Geodesic-specific resources,
# in order from most general to most specific. They should be applied in order with the later ones overriding
# the earlier ones.
#
# Every resource, for example "preferences", can be either a file or a directory.
# * If it is a file, it is loaded directly
# * If it is a directory, all the non-hidden files in that directory are loaded in glob sort order
#
# Several directories are searched for resources, in this order:
# * $base/defaults/ ($base itself defaults to /localhost/.geodesic, can be set via GEODESIC_CONFIG_HOME)
# * $base/ if and only if there is no $base/defaults/ directory
# * $base/$(dirname $DOCKER_IMAGE)/defaults/
# * $base/$(dirname $DOCKER_IMAGE)/ if and only if there is no $base/$(dirname $DOCKER_IMAGE)/defaults/ directory
# * $base/$(base $DOCKER_IMAGE)/
# * $base/$DOCKER_IMAGE/
#
# Usage: _search_geodesic_dirs array-ref resource-name
# The first argument to _search_geodesic_dirs is the name of a variable. That variable will be treated as an array
# and all the files found will be added in the order described above. The second argument is the name of the resource
# See example usages in _preferences.sh

function _search_geodesic_dirs() {
	local -n search_list=$1
	local resource=$2
	local base="${GEODESIC_CONFIG_HOME}"

	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: LOOKING for resources of type "$resource"

	if [[ ! -d $base ]]; then
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: "$base" is not a directory, giving up the search for "$resource"
		return
	fi

	if [[ -d $base/defaults ]]; then
		_expand_dir_or_file search_list "${resource}" "${base}/defaults"
	else
		_expand_dir_or_file search_list "${resource}" "${base}"
	fi

	local company=$(dirname "${DOCKER_IMAGE}")
	local stage=$(basename "${DOCKER_IMAGE}")

	if [[ $company != "." && -d $base/$company ]]; then
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for company-level resources in "$base/$company"
		if [[ -d $base/$company/defaults ]]; then
			_expand_dir_or_file search_list "${resource}" "${base}/${company}/defaults"
		else
			_expand_dir_or_file search_list "${resource}" "${base}/${company}"
		fi
	fi

	if [[ -n $stage && ($stage != $company) && -d $base/$stage ]]; then
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for repo-level resources in "$base/$stage"
		_expand_dir_or_file search_list "${resource}" "${base}/${stage}"
	fi

	if [[ -n $DOCKER_IMAGE && ($DOCKER_IMAGE != $stage) && -d $base/$DOCKER_IMAGE ]]; then
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for image-specific resources in "$base/$DOCKER_IMAGE"
		_expand_dir_or_file search_list "${resource}" "${base}/${DOCKER_IMAGE}"
	fi
}

# _expand_dir_or_file is a helper function
#
# Usage: _expand_dir_or_file array-ref resource-name [base-directory]
# Look for either a file named resource-name and a directory named resource-name.d
# * If there is a file, add that file to the array-ref
# * If there is a directory, add all the non-hidden files, except the ones matching
#   the exclusion pattern in GEODESIC_AUTO_LOAD_EXCLUSIONS, in the directory to the array-ref
function _expand_dir_or_file() {
	local -n expand_list=$1
	local resource=$2
	local dir=${3-${PWD}}
	local default_exclusion_pattern="(~|.bak|.log|.old|.orig|.disabled)$"
	local exclude="${GEODESIC_AUTO_LOAD_EXCLUSIONS:-$default_exclusion_pattern}"

	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for resources of type "$resource" in "$dir"

	for item in "${dir}/$resource" "${dir}/${resource}.d"/*; do
		if [[ -f $item ]]; then
			[[ $item =~ $exclude ]] && ([[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: excluding "$item" || true) && continue
			expand_list+=($item)
			[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: found "$item"
		fi
	done
}

# _cmd_exists checks if a given string would currently be interpreted by the shell as a command.
# We use this to avoid redefining existing commands when we expect to be creating new ones.
# usage:
#     _cmd_exists ll || alias ll='ls -l'
function _cmd_exists() {
	command -v $1 >/dev/null
}

# Because there is no easy way to invert the exit status of a command for use in an if statement
# _cmd_missing returns true if a given string would currently NOT be interpreted by the shell as a command.
function _cmd_missing() {
	if command -v $1 >/dev/null; then
		return 1
	else
		return 0
	fi
}
