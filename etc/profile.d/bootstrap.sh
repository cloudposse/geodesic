if [ "${BOOTSTRAP}" == "true" ]; then
  # Output the bootstrap script
  stty -onlcr
  cat contrib/geodesic
  exit 0
fi


