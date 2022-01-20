#!/bin/bash

# check if atmos base path is unset and verify that the stacks and components dir is in current directory
function atmos-base {
  local PATH="${1:-$PWD}"
  if [ -z "$ATMOS_BASE_PATH" ] && [ -d "$PATH/stacks" -a -d "$PATH/components" ]; then
    # echo "Set ATMOS_BASE_PATH = ${PATH}"
    export ATMOS_BASE_PATH="$PATH"
  # else
    # echo "Cannot find stacks/ and components/ in $PATH"
  fi
}

atmos-base
