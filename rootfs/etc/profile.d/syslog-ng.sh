# Root detection function defined in _preferences.sh
_root_detection

if ! $SUDO_CMD pidof syslog-ng >/dev/null; then
	$SUDO_CMD syslog-ng -f /etc/syslog-ng/syslog-ng.conf --no-caps
fi
