#!/usr/bin/env bash

if [[ -n "${GROUP}" ]] && ! id -g "${GROUP}" &>/dev/null; then
	if [[ -n "${GROUP_ID}" ]]; then
		addgroup --force-badname --gid "${GROUP_ID}" "${GROUP}" &>/dev/null
	fi
fi

if ! id "${USER}" &>/dev/null; then
	if [[ -n "${USER_ID}" ]] && [[ -n "${GROUP_ID}" ]]; then
		if [[ "${GEODESIC_OS}" = 'debian' ]]; then
			# Trust the host USER a much as permissible, to that end we need to force
			# a bad username for cases in which the username may contain dots and the
			# like.
			adduser --force-badname --uid "${USER_ID}" --gid "${GROUP_ID}" --home "${HOME}" --disabled-password --gecos '' "${USER}" &>/dev/null
		else
			adduser -D -u "${USER_ID}" -g "${GROUP_ID}" -h "${HOME}" "${USER}" &>/dev/null
		fi
	fi
fi
