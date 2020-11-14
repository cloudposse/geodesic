if ! pidof syslog-ng >/dev/null; then
	syslog-ng -f /etc/syslog-ng/syslog-ng.conf --no-caps
fi
