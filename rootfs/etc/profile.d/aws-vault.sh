#!/bin/bash

if [ -n "${AWS_VAULT}" ]; then
  # Set the Terraform `aws_assume_role_arn` based on our current context
  export TF_VAR_aws_assume_role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
  echo "* Assumed role $(green ${TF_VAR_aws_assume_role_arn})"
else
  AWS_VAULT_ARGS=("--assume-role-ttl=${AWS_VAULT_ASSUME_ROLE_TTL}")
  [ -d /localhost/.awsvault ] || mkdir -p /localhost/.awsvault
  ln -sf /localhost/.awsvault ${HOME}
  if [ "${VAULT_SERVER_ENABLED:-true}" == "true" ]; then
    curl -sSL --connect-timeout 0.1 -o /dev/null --stderr /dev/null http://169.254.169.254/latest/meta-data/iam/security-credentials
    result=$?
    if [ $result -ne 0 ]; then
        echo "* Started EC2 metadata service at $(green http://169.254.169.254/latest)"
        aws-vault server &
        AWS_VAULT_ARGS+=("--server")
     else
        echo "* EC2 metadata server already running"
     fi
  fi
fi

PROMPT_HOOKS+=("aws_vault_prompt")
function aws_vault_prompt() {
  if [ -z "${AWS_VAULT}" ]; then
    echo -e "-> Run '$(green assume-role)' to login to AWS"
  fi
}

# Alias to start a shell or run a command with an assumed role
function assume-role() {
  role=${1:-${AWS_DEFAULT_PROFILE}}

  # Do not allow nested roles
  if [ -n "${AWS_VAULT}" ]; then
    echo "Type '$(green exit)' before attempting to assume another role"
    return 1
  fi

  if [ -z "${role}" ]; then
    echo "Usage: $0 [role]"
    return 1
  fi
  # Sync the clock in the Docker Virtual Machine to the system's hardware clock to avoid time drift
  # (Only works in privileged mode)
  hwclock -s >/dev/null 2>&1 
  if [ $? -ne 0 ]; then
    echo "* $(yellow Failed to sync system time from hardware clock)"
  fi

  shift
  if [ $# -eq 0 ]; then
    aws-vault exec ${AWS_VAULT_ARGS[@]} $role -- bash -l
  else
    aws-vault exec ${AWS_VAULT_ARGS[@]} $role -- $*
  fi
}

# Alias for backwards compatbility
function use-profile() {
  assume-role $*
}

