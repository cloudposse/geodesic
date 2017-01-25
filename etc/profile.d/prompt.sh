# Define our own prompt
function geodesic-prompt() {
  # Load cluster env
  if [ -f "${CLOUD_CONFIG}" ]; then
    set -o allexport
    . "${CLOUD_CONFIG}"
    set +o allexport
  fi

  # Reprocess defaults
  if [ -f "/etc/profile.d/defaults.sh" ]; then
    . "/etc/profile.d/defaults.sh"
  fi

  # Run the aws-assume-role prompt
  console-prompt

  # Augment prompt (PS1) with some geodesic state information
  if [ -d "${CLOUD_STATE_PATH}/.git" ]; then
    GIT_STATE=$(git -C ${CLOUD_STATE_PATH} status -s)
    STATUS="[clean]";
    if [ -n "${GIT_STATE}" ]; then
      STATUS="[unsaved changes]"
    fi
  fi

  if [ -n "${CLUSTER_NAME}" ]; then
    PS1="[${CLUSTER_NAME}]\n$STATUS $PS1"
  fi
}

export PROMPT_COMMAND=geodesic-prompt


