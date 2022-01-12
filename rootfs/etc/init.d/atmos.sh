#!/bin/bash

if [ -d "${GEODESIC_WORKDIR}/stacks" -a -d "${GEODESIC_WORKDIR}/components" ]; then
  export ATMOS_BASE_PATH=${GEODESIC_WORKDIR}
fi
