if [[ $SHLVL -eq 1 ]] && ! [[ $GEODESIC_MOTD_ENABLED == "false" ]]; then
	if [ -f "/etc/motd" ]; then
		source "/etc/motd.sh"
	fi

	if [ -n "${MOTD_URL}" ]; then
		curl --fail --connect-timeout 1 --max-time 1 --silent "${MOTD_URL}"
	fi
fi

unset GEODESIC_MOTD_ENABLED
