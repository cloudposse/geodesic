if [ "${BOOTSTRAP}" == "true" ]; then
  # Output the bootstrap script
  stty -onlcr
  cat ${GEODESIC_PATH}/contrib/geodesic
  exit 0
fi


