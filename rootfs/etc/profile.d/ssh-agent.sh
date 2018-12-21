export SSH_KEY="${SSH_KEY:-/localhost/.ssh/id_rsa}"

# Attempt Re-use existing agent if one exists
if [ -f "${SSH_AGENT_CONFIG}" ]; then
	echo "* Found SSH agent config"
	. "${SSH_AGENT_CONFIG}"
fi

trap ctrl_c INT

function ctrl_c() {
	echo "* Okay, nevermind =)"
	killall -9 ssh-agent
	rm -f "${SSH_AUTH_SOCK}"
}

# Otherwise launch a new agent
if [ -z "${SSH_AUTH_SOCK}" ] || ! [ -e "${SSH_AUTH_SOCK}" ]; then
	ssh-agent | grep -v '^echo' >"${SSH_AGENT_CONFIG}"
	. "${SSH_AGENT_CONFIG}"

	# Add keys (if any) to the agent
	if [ -n "${SSH_KEY}" ] && [ -f "${SSH_KEY}" ]; then
		echo "Add your local private SSH key to the key chain. Hit ^C to skip."
		ssh-add "${SSH_KEY}"
	fi
fi

# Clean up
trap - INT
unset -f ctrl_c
