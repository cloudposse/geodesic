if [ "${SHLVL}" == "1" ]; then
	function _check_support() {
		if grep -qsE 'GenuineIntel|AuthenticAMD' /proc/cpuinfo; then
			# Running natively on Intel/AMD
			if [ "$GEODESIC_OS" = "alpine" ]; then
				red '# DEPRECATION NOTICE:'
				red '# This version of Geodesic is based on Alpine Linux and is deprecated.'
				red '# Please use the Debian-based Geodesic.'
			fi
		elif [[ $(arch) = "x86_64" ]]; then # Apple CPU emulating Intel CPU
			if [ "$GEODESIC_OS" = "alpine" ]; then
				red '# DEPRECATION NOTICE:'
				red '# Detected Apple CPU emulating Intel CPU.'
				red '# Alpine-based Geodesic does not have native Apple CPU support and is deprecated.'
				red '# Please use the Debian-based Geodesic, which does have native Apple CPU support.'
			else
				yellow '# Detected Apple CPU emulating Intel CPU. Geodesic is available with native Apple CPU support.'
				yellow '# Check your configuration to ensure you are pulling and building Geodesic with your native architecture.'
			fi
		fi
	}

	function _header() {
		local ESC=$'\e'
		local CYAN="${ESC}[36m"
		local COLOR_RESET # Have to be careful because of dark mode
		local BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
		local BANNER_COLOR="${BANNER_COLOR:-${CYAN}}"
		local BANNER_INDENT="${BANNER_INDENT:-    }"
		# See font examples at http://www.figlet.org/examples.html
		local BANNER_FONT="${BANNER_FONT:-Nancyj.flf}"

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
				local color_off="$(tput op 2>/dev/null)" # reset foreground and background colors to defaults
				tty -s && [[ -n "$color_off " ]] || BANNER_COLOR=""
				echo "${BANNER_COLOR}"
				${BANNER_COMMAND} -w 200 "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
				echo "${color_off}"
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
