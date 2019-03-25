if [[ $GEODESIC_TRACE =~ custom ]]; then
	export GEODESIC_CUSTOM_TRACE=true
else
	unset GEODESIC_CUSTOM_TRACE
fi

#.geodesic/default/
#.geodesic/$(basename $DOCKER_IMAGE)/

[[ -n $GEODESIC_CUSTOM_TRACE ]] && echo trace: GEODESIC_DOT_DIR is found to be "${GEODESIC_DOT_DIR:-<unset>}"

export GEODESIC_DOT_DIR
GEODESIC_DOT_DIR_DEFAULT="/localhost/.geodesic"

if [[ -z $GEODESIC_DOT_DIR ]]; then
	# Not set, use default
	GEODESIC_DOT_DIR="${GEODESIC_DOT_DIR_DEFAULT}"
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
		echo $(red Using default value of ${GEODESIC_DOT_DIR_DEFAULT} instead)
		GEODESIC_DOT_DIR="${GEODESIC_DOT_DIR_DEFAULT}"
	fi
fi

unset GEODESIC_DOT_DIR_DEFAULT

[[ -n $GEODESIC_CUSTOM_TRACE ]] && echo trace: GEODESIC_DOT_DIR is ultimately set to "${GEODESIC_DOT_DIR}"

## Save shell history in the most specific place
HISTFILE_LIST=(${HISTFILE:-${GEODESIC_DOT_DIR}/history})
_search_geodesic_dirs HISTFILE_LIST history
HISTFILE="${HISTFILE_LIST[-1]}"
[[ -n $GEODESIC_CUSTOM_TRACE ]] && echo trace: HISTFILE set to "${HISTFILE}"
unset HISTFILE_LIST

## Load user's custom preferences
PREFERENCE_LIST=()
_search_geodesic_dirs PREFERENCE_LIST preferences
for file in "${PREFERENCE_LIST[@]}"; do
	[[ -n $GEODESIC_CUSTOM_TRACE ]] && echo trace: loading preference file "$file"
	source "$file"
done
unset PREFERENCE_LIST
