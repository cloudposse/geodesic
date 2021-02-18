COLOR_RESET="[0m"
BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"
BANNER_FONT="${BANNER_FONT:-Nancyj.flf}" # " IDE parser fix

if [ "${SHLVL}" == "1" ]; then
	function _header() {
		local vstring
		# Display a banner message for interactive shells (if we're not in aws-vault or aws-okta)
		[ -n "${GEODESIC_VERSION}" ] && vstring=" version ${GEODESIC_VERSION}"
		(source /etc/os-release && printf "# Geodesic${vstring} based on %s\n\n" "$PRETTY_NAME")
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
