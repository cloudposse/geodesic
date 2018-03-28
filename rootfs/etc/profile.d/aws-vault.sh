#!/bin/bash

[ -d /localhost/.awsvault ] || mkdir /localhost/.awsvault
ln -sf /localhost/.awsvault ${HOME}

# Alias to start a shell or run a command with an assumed role
function assume-role() {
  role=$1
  shift
  if [ $# -eq 0 ]; then
    aws-vault exec $role bash
  else
    aws-vault exec $role $*
  fi
}

# Alias for backwards compatbility
function use-profile() {
  assume-role $*
}

