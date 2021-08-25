COLOR_RESET="[0m"
BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"
BANNER_FONT="${BANNER_FONT:-Nancyj.flf}" # " IDE parser fix

if [ "${SHLVL}" == "1" ]; then
  function _check_support() {
		[[ $(arch) != "x86_64" ]] || grep -qs GenuineIntel /proc/cpuinfo && return
		echo
		echo
		red '**********************************************************************'
		red '**********************************************************************'
		red '**                                                                  **'
		red '**    You appear to be running Geodesic on an Apple M1 CPU          **'
		red '**  Geodesic is not supported on the Apple M1 and has known issues  **'
		red '**     See https://github.com/cloudposse/geodesic/issues/719        **'
		red '**                                                                  **'
		red '**********************************************************************'
		red '**********************************************************************'
		echo
		echo
  }

	function _header() {
		local vstring
		local debian_version="/etc/debian_version"

		# Development version of GEODESIC_VERSION might have version string
		# like ' (0.143.1-7-g444f3c8/branch)' (note leading space)
		# so we clean that up a bit
		vstring=$(printf "%s" "${GEODESIC_VERSION}" | sed -E 's/^ ?\((.*)\)/\1/')
		# Display a banner message for interactive shells (if we're not in aws-vault or aws-okta)
		[ -n "${vstring}" ] && vstring=" version ${vstring}"
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
			else
			  ${BANNER_COMMAND}
			fi
		fi
	}
	# We call _check_support twice so that the warning appears
	# both above and below the banner
	_check_support
	_header
	_check_support
	unset _check_support
	unset _header
fi
