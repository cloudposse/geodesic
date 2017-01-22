# Define our own prompt
function geodesic-prompt() {
  if [ -f "${CLOUD_CONFIG}" ]; then
		set -o allexport
		. "${CLOUD_CONFIG}"
		set +o allexport
  fi
  console-prompt
  local GIT_STATE=$(git -C ${CLOUD_STATE_PATH} status -s)
  local STATUS="[clean]";
  if [ -n "${GIT_STATE}" ]; then
    STATUS="[unsaved changes]"
  fi
  if [ -n "${CLUSTER_NAME}" ]; then
    PS1="[${CLUSTER_NAME}]\n$STATUS $PS1"
  fi
}

export PROMPT_COMMAND=geodesic-prompt


