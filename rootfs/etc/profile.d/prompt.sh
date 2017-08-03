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

  # Augment prompt (PS1) with some geodesic state information
  if [ -d "${CLUSTER_REPO_PATH}/.git" ]; then
    GIT_STATE=$(git -C ${CLUSTER_REPO_PATH} diff-files --no-ext-diff)
    STATUS="\[✅\]";
    if [ -n "${GIT_STATE}" ]; then
      STATUS="\[❌\]"
    fi
  fi

  if [ -n "${CLUSTER_NAME}" ]; then
    PS1=" \[⧉\] ${CLUSTER_NAME}\n$STATUS  $ROLE_PROMPT \W \[➤\] "
  fi
}

export PROMPT_COMMAND=geodesic-prompt
