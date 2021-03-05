COLOR_RESET="[0m"
BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"
BANNER_FONT="${BANNER_FONT:-Nancyj.flf}" # " IDE parser fix

if [ "${SHLVL}" == "1" ]; then
	function _header() {
		local vstring
		local debian_version="/etc/debian_version"

		# Display a banner message for interactive shells (if we're not in aws-vault or aws-okta)
		[ -n "${GEODESIC_VERSION}" ] && vstring=" version ${GEODESIC_VERSION}"
		if source /etc/os-release; then
			[[ -r $debian_version ]] && VERSION_ID=$(cat $debian_version)
			printf "# Geodesic${vstring} based on %s (%s)\n\n" "$PRETTY_NAME" "$VERSION_ID"
		fi
		if [ -n "${BANNER}" ]; then
			if [ "$BANNER_COMMAND" == "figlet" ]; then
				echo "${BANNER_COLOR}"
				${BANNER_COMMAND} -w 200 "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
				echo "${COLOR_RESET}"
			elif [ "$BANNER_COMMAND" == "figurine" ]; then
				${BANNER_COMMAND} -f "${BANNER_FONT}" "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
			fi
		fi
	}
	_header
	unset _header
fi
