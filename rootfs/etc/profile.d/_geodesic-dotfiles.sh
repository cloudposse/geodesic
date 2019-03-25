# bash funnctions to import

# Given the name of a resource, _search_geodesic_dirs assembles an array of matching, Geodesic-specific resources,
# in order from most general to most specific. They should be applied in order with the later ones overriding
# the earlier ones.
#
# Every resource, for example "preferences", can be either a file or a directory.
# * If it is a file, it is loaded directly
# * If it is a directory, all the non-hidden files in that directory are loaded in glob sort order
#
# Several directories are searched for resources, in this order:
# * $base/defaults/ ($base itself defaults to /localhost/.geodesic, can be set via GEODESIC_DOT_DIR)
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
	local base="${GEODESIC_DOT_DIR}"

	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for resources of type "$resource"

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

	if [[ -n $company && -d $base/$company ]]; then
		if [[ -d $base/$company/defaults ]]; then
			_expand_dir_or_file search_list "${resource}" "${base}/${company}/defaults"
		else
			_expand_dir_or_file search_list "${resource}" "${base}/${company}"
		fi
	fi

	if [[ -n $stage && ($stage != $company) && -d $base/$stage ]]; then
		_expand_dir_or_file search_list "${resource}" "${base}/${stage}"
	fi

	if [[ -n $DOCKER_IMAGE && -d $base/$DOCKER_IMAGE ]]; then
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
	local dir=${3-${PWD}}
	local default_exclusion_pattern="(~|.old|.orig|.disabled)$"
	local exclude="${GEODESIC_AUTO_LOAD_EXCLUSIONS:-$default_exclusion_pattern}"

	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: looking for resources of type "$resource" in "$dir"

	for item in "${dir}/$2" "${dir}/${2}.d"/*; do
		if [[ -f $item ]]; then
			[[ $item =~ $exclude ]] && continue
			expand_list+=($item)
			[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: found "$item"
		fi
	done
}
