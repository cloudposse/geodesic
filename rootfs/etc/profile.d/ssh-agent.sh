export SSH_KEY="${SSH_KEY:-/localhost/.ssh/id_rsa}"

if [ "$SSH_AUTH_SOCK_HOST" != "" ]; then
    export SSH_AUTH_SOCK="/var/tmp/ssh-geouser"
    sudo socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork,user=geouser,group=geouser,mode=777 UNIX-CONNECT:$SSH_AUTH_SOCK_HOST  &
    echo "Looks like we have a host ssh-agent socket at $SSH_AUTH_SOCK_HOST. Mapping to user socket at $SSH_AUTH_SOCK"
fi

function _load_sshagent_env() {
  [[ -r "${SSH_AGENT_CONFIG}" ]] && eval "$(<${SSH_AGENT_CONFIG})" >/dev/null
}

function _launch_sshagent() {
  (umask 066; ssh-agent > "${SSH_AGENT_CONFIG}")
}

function _ensure_sshagent_dead() {
  killall ssh-agent &> /dev/null
  rm -f "${SSH_AGENT_CONFIG}"
}

function _ensure_valid_sshagent_env() {
  ssh-add -l &>/dev/null
  if [[ $? -gt 1 ]]; then
    # Could not open a connection to your authentication agent.

    _load_sshagent_env
    ssh-add -l &>/dev/null
    if [[ $? -gt 1 ]]; then
        # Start agent and store agent connection info.
        _ensure_sshagent_dead
        _launch_sshagent
    fi
  fi
  _load_sshagent_env
  return
}

trap ctrl_c INT

function ctrl_c() {
	echo "* Okay, nevermind =)"
	killall -9 ssh-agent
	rm -f "${SSH_AUTH_SOCK}"
}

_ensure_valid_sshagent_env

# Add keys (if any) to the agent
if [ -n "${SSH_KEY}" ] && [ -f "${SSH_KEY}" ]; then
    echo "Add your local private SSH key to the key chain. Hit ^C to skip."
    ssh-add "${SSH_KEY}"
fi

# Clean up
trap - INT
unset -f ctrl_c

