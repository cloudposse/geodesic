if ! pidof syslog-ng >/dev/null; then
    SUDO=""
    if [ $(id -u) != 0 ]; then
        # If we are running as a user, sbin isn't in the path and we need to start via sudo
        PATH=/usr/sbin:/usr/bin:/bin:/sbin
        SUDO="sudo"
    fi
    $SUDO syslog-ng -f /etc/syslog-ng/syslog-ng.conf --no-caps
fi
