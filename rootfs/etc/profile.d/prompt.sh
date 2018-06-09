#!/usr/bin/env bash
# Allow bash to check the window size to keep prompt with relative to window size
shopt -s checkwinsize

export PROMPT_COMMAND=prompter
function prompter() {
    for hook in ${PROMPT_HOOKS[@]}; do
        "${hook}"
    done
}

PROMPT_HOOKS+=("reload")
function reload() {
  eval $(resize)
}

PROMPT_HOOKS+=("terraform_prompt")
function terraform_prompt() {
  shopt -s nullglob
  TF_FILES=(*.tf)
  if [ ! -z "${TF_FILES}" ]; then
    if [ ! -d ".terraform" ]; then
      echo -e "-> Run 'init-terraform' to use this project"
    fi
  fi
}

# Define our own prompt
PROMPT_HOOKS+=("geodesic_prompt")
function geodesic_prompt() {

  WHITE_HEAVY_CHECK_MARK=$'\u2705'
  BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4'
  TWO_JOINED_SQUARES=$'\u29C9'
  CROSS_MARK=$'\u274C'

  if [ -n "$AWS_VAULT" ]; then
    export STATUS=${WHITE_HEAVY_CHECK_MARK}
  else
    export STATUS=${CROSS_MARK}
  fi

  if [ -n "${AWS_VAULT}" ]; then
    ROLE_PROMPT="(${AWS_VAULT})"
  else
    ROLE_PROMPT="(none)"
  fi

  if [ -n "${BANNER}" ]; then
    PS1=$' ${TWO_JOINED_SQUARES}'" ${BANNER}\n"$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  else
    PS1=$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  fi
  export PS1
}
