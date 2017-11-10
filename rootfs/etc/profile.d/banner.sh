COLOR_RESET="[0m"
BANNER_COLOR="${BANNER_COLOR:-[36m}"
BANNER_INDENT="${BANNER_INDENT:-    }"

# Display a banner message for interactive shells
if [ -n "${BANNER}" ]; then
  echo "${BANNER_COLOR}"
  figlet -w 200 "${BANNER}" | sed "s/^/${BANNER_INDENT}/"
  echo "${COLOR_RESET}"
fi
