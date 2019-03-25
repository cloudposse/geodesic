## Load user's custom overrides
OVERRIDE_LIST=()
_search_geodesic_dirs OVERRIDE_LIST overrides
for file in "${OVERRIDE_LIST[@]}"; do
	[[ -n $GEODESIC_CUSTOM_TRACE ]] && echo trace: loading override file "$file"
	source "$file"
done
unset OVERRIDE_LIST

unset GEODESIC_CUSTOM_TRACE
