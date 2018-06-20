#!/usr/bin/env bash
export AWS_VAULT=${AWS_DEFAULT_PROFILE}

function assume-role() {
  role=${1:-${AWS_DEFAULT_PROFILE}}

  if [ -z "${role}" ]; then
    echo "Usage: $0 [role]"
    return 1
  fi
  # Sync the clock in the Docker Virtual Machine to the system's hardware clock to avoid time drift
  # (Only works in privileged mode)
  hwclock -s >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "* Failed to sync system time from hardware clock"
  fi

  shift
  if [ $# -eq 0 ]; then
    export AWS_TEMP_PROFILE=${AWS_DEFAULT_PROFILE}
    export AWS_DEFAULT_PROFILE=${role}
    export AWS_VAULT=${role}
  else
    aws-google-auth ${AWS_VAULT_ARGS[@]} -p ${role} -r ${AWS_REGION} && \
    export AWS_VAULT=${role}
  fi
}

function leave-role() {
    export AWS_DEFAULT_PROFILE=${AWS_TEMP_PROFILE:-default}
    export AWS_VAULT=${AWS_DEFAULT_PROFILE}
}