if [[ -n $GEODESIC_HOST_UID ]] && [[ -n $GEODESIC_HOST_GID ]] && df -a | grep -q /localhost.bindfs; then
  # Things are really wonky if this fails -- i think 'set -e' is good here
  set -e
  if [ -d /localhost ]; then
    mv /localhost /localhost.from-docker
    mkdir /localhost
  fi
  bindfs --create-for-user="$GEODESIC_HOST_UID" --create-for-group="$GEODESIC_HOST_GID" /localhost.bindfs /localhost
fi
cd $GEODESIC_WORKDIR
