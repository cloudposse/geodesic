COLOR_RESET="[0m"
BANNER_COMMAND="${BANNER_COMMAND:-figurine}"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"
BANNER_FONT="${BANNER_FONT:-Nancyj.flf}"

if [ "${SHLVL}" == "1" ]; then
	# Display a banner message for interactive shells (if we're not in aws-vault or aws-okta)
	if [ -n "${BANNER}" ]; then
		if [ "$BANNER_COMMAND" == "figlet" ]; then
			echo "${BANNER_COLOR}"
			${BANNER_COMMAND} -w 200 "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
			echo "${COLOR_RESET}"
		elif [ "$BANNER_COMMAND" == "figurine" ]; then
			${BANNER_COMMAND} -f "${BANNER_FONT}" "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
		fi
	fi
fi
