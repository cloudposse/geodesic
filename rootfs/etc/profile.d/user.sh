#!/usr/bin/env bash

id "${USER}" &>/dev/null
if [[ "$?" -ne 0 ]]; then
    adduser -D -H ${USER} &>/dev/null
fi
