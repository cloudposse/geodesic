export GEODESIC_SHELL=true
export SSH_AGENT_CONFIG=${LOCAL_STATE}/.ssh-agent

cloud init

# Attempt Re-use existing agent if one exists
if [ -f "${SSH_AGENT_CONFIG}" ]; then
  . "${SSH_AGENT_CONFIG}"
fi

# Otherwise launch a new agent
if [ -z "${SSH_AUTH_SOCK}" ] || ! [ -e "${SSH_AUTH_SOCK}" ]; then
  ssh-agent |grep -v '^echo' > "${SSH_AGENT_CONFIG}"
  . "${SSH_AGENT_CONFIG}"
fi

[ -f "${HOME}/.bashrc" ] && source "${HOME}/.bashrc"
