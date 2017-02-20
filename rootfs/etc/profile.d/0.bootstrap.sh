if [ "${BOOTSTRAP}" == "true" ]; then
  # Output the bootstrap script
  stty -onlcr
  cat /opt/geodesic
  exit 0
fi


