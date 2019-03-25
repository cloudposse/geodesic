if [[ $GEODESIC_TRACE =~ custom ]]; then
	export _GEODESIC_TRACE_CUSTOMIZATION=true
else
	unset _GEODESIC_TRACE_CUSTOMIZATION
fi

#.geodesic/default/
#.geodesic/$(basename $DOCKER_IMAGE)/

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_DOT_DIR is found to be "${GEODESIC_DOT_DIR:-<unset>}"

export GEODESIC_DOT_DIR
_GEODESIC_DOT_DIR_DEFAULT="/localhost/.geodesic"

if [[ -z $GEODESIC_DOT_DIR ]]; then
	# Not set, use default
	GEODESIC_DOT_DIR="${_GEODESIC_DOT_DIR_DEFAULT}"
elif [[ ! -d $GEODESIC_DOT_DIR ]]; then
	# Set, but not correctly. See if it is relative to /localhost (host ~)
	if [[ -d /localhost/$GEODESIC_DOT_DIR ]]; then
		GEODESIC_DOT_DIR="/localhost/$GEODESIC_DOT_DIR"
		# See if it is a full host path ending under host ~
	elif [[ -d /localhost/$(basename $GEODESIC_DOT_DIR) ]]; then
		GEODESIC_DOT_DIR="/localhost/$(basename $GEODESIC_DOT_DIR)"
	else
		echo $(red Invalid value of GEODESIC_DOT_DIR: "${GEODESIC_DOT_DIR}")
		echo $(red GEODESIC_DOT_DIR should be relative to /localhost \(normally your home directory\))
		echo $(red Using default value of ${_GEODESIC_DOT_DIR_DEFAULT} instead)
		GEODESIC_DOT_DIR="${_GEODESIC_DOT_DIR_DEFAULT}"
	fi
fi

unset _GEODESIC_DOT_DIR_DEFAULT

[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: GEODESIC_DOT_DIR is ultimately set to "${GEODESIC_DOT_DIR}"

function _geodesic_set_histfile() {
	## Save shell history in the most specific place
	local histfile_list=(${HISTFILE:-${GEODESIC_DOT_DIR}/history})
	_search_geodesic_dirs HISTFILE_LIST history
	HISTFILE="${histfile_list[-1]}"
	[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: HISTFILE set to "${HISTFILE}"
}
_geodesic_set_histfile
unset -f _geodesic_set_histfile

function _load_geodesic_preferences() {
	local preference_list=()

	_search_geodesic_dirs preference_list preferences
	for file in "${preference_list[@]}"; do
		[[ -n $_GEODESIC_TRACE_CUSTOMIZATION ]] && echo trace: loading preference file "$file"
		source "$file"
	done
}

_load_geodesic_preferences
unset -f _load_geodesic_preferences
