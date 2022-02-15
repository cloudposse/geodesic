COLOR_RESET="[0m"
BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"
BANNER_FONT="${BANNER_FONT:-Nancyj.flf}" # " IDE parser fix

if [ "${SHLVL}" == "1" ]; then
	function _check_support() {
		[[ $(arch) != "x86_64" ]] || grep -qsE 'GenuineIntel|AuthenticAMD' /proc/cpuinfo && return
		yellow '# Detected Apple M1 emulating Intel CPU. Support for this configuration is evolving.'
		yellow '# Report issues and read about solutions at https://github.com/cloudposse/geodesic/issues/719'
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
	_check_support
	_header
	unset _check_support
	unset _header
fi
