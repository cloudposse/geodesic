if pidof syslog-ng >/dev/null; then
    echo "* syslog-ng is already running"
else
    syslog-ng -f /etc/syslog-ng/syslog-ng.conf
fi
