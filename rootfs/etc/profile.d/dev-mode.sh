#!/usr/bin/env bash

if [ "${DEV}" == "true" ]; then
    echo "Installation of Ansible dependencies for the Development mode..."
    make -C /conf/ansible deps
fi
