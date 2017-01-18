#!/bin/bash
DOCKER_IMAGE=${DOCKER_IMAGE:-cloudposse/geodesic}
DOCKER_TAG=${DOCKER_TAG:-latest}
APP_NAME=${APP_NAME:-geodesic}
INSTALL_PATH=${INSTALL_PATH:-/usr/local/bin}
OUTPUT=${OUTPUT:-/dev/null}  # Replace with /dev/stdout to audit output
REQUIRE_PULL=${REQUIRE_PULL:-true}

which docker >/dev/null
if [ $? -ne 0 ]; then
  echo "Docker is requried to run ${APP_NAME}"
  exit 1
fi

which tee >/dev/null
if [ $? -ne 0 ]; then
  echo "Tee is requried to install ${APP_NAME}"
  exit 1
fi

if [ ! -w "${INSTALL_PATH}" ]; then
  echo "Cannot write to ${INSTALL_PATH}. Please retry using sudo."
  exit 1
fi

echo "# Installing ${APP_NAME} from ${DOCKER_IMAGE}:${DOCKER_TAG}..."
if [ "${REQUIRE_PULL}" == "true" ]; then
  docker pull "${DOCKER_IMAGE}:${DOCKER_TAG}"
fi 

(docker run --name "${APP_NAME}-install" --rm -it "${DOCKER_IMAGE}:${DOCKER_TAG}" | tee "${INSTALL_PATH}/${APP_NAME}" > ${OUTPUT}) && \
  chmod 755 "${INSTALL_PATH}/${APP_NAME}"

if [ $? -eq 0 ]; then
  echo "# Installed ${APP_NAME} to ${INSTALL_PATH}/${APP_NAME}"
  exit 0
else
  echo "# Failed to install ${APP_NAME}"
  echo "# Please let us know! Send an email to < hello@cloudposse.com > with what went wrong."
  exit 1
fi
