# Tell `tsh` to use our open port for SAML authentication
# See https://github.com/gravitational/teleport/blob/92e5bf508121360b9151357817a5ac1ea43ebb17/tool/tsh/tsh.go#L175
export TELEPORT_LOGIN_BIND_ADDR=":${GEODESIC_PORT}"

# Fill in a default value for TELEPORT_PROXY. Do not change if it is set, even if it is empty.
export TELEPORT_PROXY="${TELEPORT_PROXY-tele.${DOCKER_IMAGE#*.}}"

# Fill in a default value for TELEPORT_LOGIN, which is the user name part of the ssh destination
# Do not change if it is set, even if it is empty.
export TELEPORT_LOGIN="${TELEPORT_LOGIN-admin}"
