#!/bin/bash

# check if atmos base path is unset and verify that the stacks and components dir is in current directory
if [ -z $ATMOS_BASE_PATH ] && [ -d "${GEODESIC_WORKDIR}/stacks" -a -d "${GEODESIC_WORKDIR}/components" ]; then
  export ATMOS_BASE_PATH=${GEODESIC_WORKDIR}
  echo "Set ATMOS_BASE_PATH = ${GEODESIC_WORKDIR}"
fi
