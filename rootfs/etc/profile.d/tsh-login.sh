#!/bin/bash

function tsh-login() {
	if (( $# == 0 )); then
		tsh login --bind-addr=:${GEODESIC_PORT} --proxy=${TELEPORT_LOGIN_PROXY:-tele.${DOCKER_IMAGE#*.}} $STAGE
	else
		tsh login --bind-addr=:${GEODESIC_PORT} --proxy=${TELEPORT_LOGIN_PROXY:-tele.${DOCKER_IMAGE#*.}} $*
	fi
}
