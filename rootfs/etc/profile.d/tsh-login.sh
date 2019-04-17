#!/bin/bash

function tsh-login() {
	tsh login --bind-addr=:${GEODESIC_PORT} --proxy=${TELEPORT_PROXY_DOMAIN_NAME:-tele.${DOCKER_IMAGE#*.}} $*
}
