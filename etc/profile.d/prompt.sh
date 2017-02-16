function reload() {
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
}

# Define our own prompt
function geodesic-prompt() {
  reload

  # Run the aws-assume-role prompt
  console-prompt


  # Augment prompt (PS1) with some geodesic state information
  if [ -d "${CLUSTER_REPO_PATH}/.git" ]; then
    GIT_STATE=$(git -C ${CLUSTER_REPO_PATH} diff-files --no-ext-diff --quiet)
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


