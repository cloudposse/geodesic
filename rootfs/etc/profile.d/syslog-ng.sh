# Determine the command to use for checking if syslog-ng is running
if [ -f "/etc/alpine-release" ]; then
    # Alpine Linux
    SYSLOG_NG_PID="pidof syslog-ng"
else
    # Assumes Debian or other distributions
    SYSLOG_NG_PID="pgrep -x syslog-ng"
fi

# Check if syslog-ng is running and start it if not
if ! $SYSLOG_NG_PID >/dev/null; then
    syslog-ng -f /etc/syslog-ng/syslog-ng.conf --no-caps
fi
