#!/bin/bash

[ -d /localhost/.awsvault ] || mkdir /localhost/.awsvault
ln -sf /localhost/.awsvault ${HOME}

# Alias to start a shell or run a command with an assumed role
function assume-role() {
  role=${1:-${AWS_DEFAULT_PROFILE}}
  if [ -z "${role}" ]; then
    echo "Usage: $0 [role]"
    return 1
  fi
  shift
  if [ $# -eq 0 ]; then
    aws-vault exec $role -- bash -l
  else
    aws-vault exec $role -- $*
  fi
}

# Alias for backwards compatbility
function use-profile() {
  assume-role $*
}

