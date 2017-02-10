#!/bin/bash
DOCKER_IMAGE=${DOCKER_IMAGE:-cloudposse/geodesic}
DOCKER_TAG=${DOCKER_TAG:-latest}
APP_NAME=${APP_NAME:-geodesic}
INSTALL_PATH=${INSTALL_PATH:-/usr/local/bin}
OUTPUT=${OUTPUT:-/dev/null}  # Replace with /dev/stdout to audit output
REQUIRE_PULL=${REQUIRE_PULL:-true}

if [ "${GEODESIC_SHELL}" == "true" ]; then
  echo "Installer cannot be run from inside a geodesic shell"
  exit 1
fi

# Check if docker is installed
which docker >/dev/null
if [ $? -ne 0 ]; then
  echo "Docker is requried to run ${APP_NAME}"
  exit 1
fi

# Check that we can connect to docker
docker ps >/dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Unable to communicate with docker daemon. Make sure your environment is properly configured and then try again."
  exit 1
fi

# Check if tee is installed
which tee >/dev/null
if [ $? -ne 0 ]; then
  echo "Tee is requried to install ${APP_NAME}"
  exit 1
fi

# Check that we can write to install path
if [ ! -w "${INSTALL_PATH}" ]; then
  echo "Cannot write to ${INSTALL_PATH}. Please retry using sudo."
  exit 1
fi

# Proceed with installation
echo "# Installing ${APP_NAME} from ${DOCKER_IMAGE}:${DOCKER_TAG}..."
if [ "${REQUIRE_PULL}" == "true" ]; then
  docker pull "${DOCKER_IMAGE}:${DOCKER_TAG}"
  if [ $? -ne 0 ]; then
    echo "Failed to pull down ${DOCKER_IMAGE}:${DOCKER_TAG}"
    exit 1
  fi
fi 

# Sometimes docker might not exit cleanly 
docker rm "${APP_NAME}-install" >/dev/null 2>&1

(docker run --name "${APP_NAME}-install" --rm --tty "${DOCKER_IMAGE}:${DOCKER_TAG}" | tee "${INSTALL_PATH}/${APP_NAME}" > ${OUTPUT}) && \
  chmod 755 "${INSTALL_PATH}/${APP_NAME}"

if [ $? -eq 0 ]; then
  echo "# Installed ${APP_NAME} to ${INSTALL_PATH}/${APP_NAME}"
  exit 0
else
  echo "# Failed to install ${APP_NAME}"
  echo "# Please let us know! Send an email to < hello@cloudposse.com > with what went wrong."
  exit 1
fi
