export GEODESIC_SHELL=true
export SSH_AGENT_CONFIG=${LOCAL_STATE}/.ssh-agent

function assume-role() {
  role=$1
  shift
  if [ $# -eq 0 ]; then
    aws-vault exec $role bash
  else
    aws-vault exec $role $*
  fi
}

function use-profile() {
  assume-role $*
}

