if [[ $SHLVL -eq 1 ]]; then
	if [ -f "/etc/motd" ]; then
		cat "/etc/motd"
	fi

	if [ -n "${MOTD_URL}" ]; then
		curl --fail --connect-timeout 1 --max-time 1 --silent "${MOTD_URL}"
	fi
fi
