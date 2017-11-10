#!/usr/bin/env bash
# Allow bash to check the window size to keep prompt with relative to window size
shopt -s checkwinsize

PROMPT_HOOKS=()

export PROMPT_COMMAND=prompter
function prompter() {
    for hook in ${PROMPT_HOOKS[@]}; do
        "${hook}"
    done
}


# Run the aws-assume-role prompt
PROMPT_HOOKS+=("console-prompt")

PROMPT_HOOKS+=("reload")
function reload() {
  # Reprocess defaults
  if [ -f "/etc/profile.d/defaults.sh" ]; then
    . "/etc/profile.d/defaults.sh"
  fi

  # Load a Cluster .bashrc (if one exists & not already loaded)
  if [ -f "${CLUSTER_REPO_PATH}/.bashrc" ]; then
    if [ "${CLUSTER_REPO_PATH_BASHRC}" != "${CLUSTER_REPO_PATH}/.bashrc" ]; then
      CLUSTER_REPO_PATH_BASHRC="${CLUSTER_REPO_PATH}/.bashrc"
      . "${CLUSTER_REPO_PATH_BASHRC}"
    fi
  fi
  eval $(resize)
}

PROMPT_HOOKS+=("terraform_prompt")
function terraform_prompt() {
  shopt -s nullglob
  TF_FILES=(*.tf)
  if [ ! -z "${TF_FILES}" ]; then
    if [ ! -d ".terraform" ]; then
      if [ -f Makefile ]; then
        echo "Run 'make init' to use this project"
      fi
    fi
  fi
}

# Define our own prompt
PROMPT_HOOKS+=("geodesic_prompt")
function geodesic_prompt() {

  WHITE_HEAVY_CHECK_MARK=$'\u2705 '
  BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4 '
  TWO_JOINED_SQUARES=$'\u29C9 '
  CROSS_MARK=$'\u274C '

  if [ -n "$AWS_IAM_ROLE_ARN" ]; then
    export STATUS=${WHITE_HEAVY_CHECK_MARK}
  elif [ $AWS_SESSION_TTL -gt 0 ] && [ -n "$AWS_SESSION_TOKEN" ]; then
    export STATUS=${WHITE_HEAVY_CHECK_MARK}
  else
    export STATUS=${CROSS_MARK}
  fi

  if [ -n "${CLUSTER_NAME}" ]; then
    PS1=$' ${TWO_JOINED_SQUARES}'" ${CLUSTER_NAME}\n"$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  else
    PS1=$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  fi
  export PS1
}
