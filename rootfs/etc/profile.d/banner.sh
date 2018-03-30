COLOR_RESET="[0m"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"

if [ -z "${AWS_VAULT}" ]; then
  # Display a banner message for interactive shells (if we're not in aws-vault)
  if [ -n "${BANNER}" ]; then
    echo "${BANNER_COLOR}"
    figlet -w 200 "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
    echo "${COLOR_RESET}"
  fi
fi
