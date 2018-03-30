#!/bin/bash

if [ -n "${AWS_VAULT}" ]; then
  # Set the Terraform `aws_assume_role_arn` based on our current context
  export TF_VAR_aws_assume_role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
  echo "* Assumed role ${TF_VAR_aws_assume_role_arn}"
else
  [ -d /localhost/.awsvault ] || mkdir /localhost/.awsvault
  ln -sf /localhost/.awsvault ${HOME}
fi

PROMPT_HOOKS+=("aws_vault_prompt")
function aws_vault_prompt() {
  if [ -z "${AWS_VAULT}" ]; then
    echo -e "-> Run 'assume-role' to login to AWS"
  fi
}

# Alias to start a shell or run a command with an assumed role
function assume-role() {
  role=${1:-${AWS_DEFAULT_PROFILE}}

  # Do not allow nested roles
  if [ -n "${AWS_VAULT}" ]; then
    echo "Type 'exit' before attempting to assume another role"
    return 1
  fi

  if [ -z "${role}" ]; then
    echo "Usage: $0 [role]"
    return 1
  fi
  shift
  if [ $# -eq 0 ]; then
    aws-vault exec --assume-role-ttl=${AWS_VAULT_ASSUME_ROLE_TTL} $role -- bash -l
  else
    aws-vault exec --assume-role-ttl=${AWS_VAULT_ASSUME_ROLE_TTL} $role -- $*
  fi
}

# Alias for backwards compatbility
function use-profile() {
  assume-role $*
}

