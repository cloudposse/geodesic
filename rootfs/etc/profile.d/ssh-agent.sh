#!/usr/bin/env bash
# Attempt Re-use existing agent if one exists
if [ -f "${SSH_AGENT_CONFIG}" ]; then
  echo "* Found SSH agent config"
  . "${SSH_AGENT_CONFIG}"
fi

# Otherwise launch a new agent
if [ -z "${SSH_AUTH_SOCK}" ] || ! [ -e "${SSH_AUTH_SOCK}" ]; then
  ssh-agent |grep -v '^echo' > "${SSH_AGENT_CONFIG}"
  . "${SSH_AGENT_CONFIG}"

  # Add keys (if any) to the agent
  if [ -f /localhost/.ssh/id_rsa ]; then
    echo ". Add your local private SSH key to the key chain. Hit ^C to skip."
    ssh-add /localhost/.ssh/id_rsa
  fi
fi
