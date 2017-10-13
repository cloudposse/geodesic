#!/usr/bin/env bash
# Allow bash to check the window size to keep prompt with relative to window size
shopt -s checkwinsize

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


# Define our own prompt
function geodesic-prompt() {
  reload

  # Run the aws-assume-role prompt
  console-prompt
  local WHITE_HEAVY_CHECK_MARK=$'\u2705 '
  local BLACK_RIGHTWARDS_ARROWHEAD=$'\u27A4 '
  local TWO_JOINED_SQUARES=$'\u29C9 '
  local CROSS_MARK=$'\u274C '
  local STATUS=${CROSS_MARK}

  if [ $AWS_SESSION_TTL -gt 0 ]; then
    STATUS=${WHITE_HEAVY_CHECK_MARK}
  fi

  if [ -n "${CLUSTER_NAME}" ]; then
    PS1=$' ${TWO_JOINED_SQUARES}'" ${CLUSTER_NAME}\n"$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  else
    PS1=$'${STATUS}'"  $ROLE_PROMPT \W "$'${BLACK_RIGHTWARDS_ARROWHEAD} '
  fi
  export PS1
}

export PROMPT_COMMAND=geodesic-prompt
