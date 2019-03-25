# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named Ω_overrides.sh. The leading Ω (Capital Greek Omega) is needed to ensure this file executes after
# other files that this function needs to be able to see.
# This file should be the last file in profile.d to execute.
# This loads user's overrides, which take actions based on any setup that has already occurred.
# This must come after all setup has happened so that the final configuration is availble for inspection,
# and there must not be any configuration after this to ensure that anything set here remains set as the user intended.

## Load user's custom overrides

function _load_geodesic_overrides() {
	local override_list=()

	_search_geodesic_dirs override_list overrides
	for file in "${override_list[@]}"; do
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: loading override file "$file"
		source "$file"
	done
}

[[ ${GEODESIC_CUSTOMIZATION_DISABLED-false} != false ]] || _load_geodesic_overrides
unset -f _load_geodesic_overrides

unset _GEODESIC_TRACE_CUSTOMIZATION
