## Load user's custom overrides

function _load_geodesic_overrides() {
	local override_list=()

	_search_geodesic_dirs override_list overrides
	for file in "${override_list[@]}"; do
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: loading override file "$file"
		source "$file"
	done
}

_load_geodesic_overrides
unset -f _load_overrides

unset _GEODESIC_TRACE_CUSTOMIZATION
