#!/usr/bin/env bash

id "${USER}" &>/dev/null
if [[ "$?" -ne 0 ]]; then
	if [[ -n "${USER_ID}" ]] && [[ -n "${GROUP_ID}" ]]; then
		adduser -D -u ${USER_ID} -g ${GROUP_ID} -h ${HOME} ${USER} &>/dev/null
	fi
fi
