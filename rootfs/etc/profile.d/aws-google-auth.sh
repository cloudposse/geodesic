#!/usr/bin/env bash

if [ -n "${AWS_GOOGLE_AUTH}" ]; then

    export AWS_VAULT_ARGS=("-D -d=${AWS_VAULT_ASSUME_ROLE_TTL}")

    PROMPT_HOOKS+=("aws_vault_prompt")
    function aws_vault_prompt() {
      if [ -z "${AWS_VAULT}" ]; then
        echo -e "-> Run 'assume-role' to login to AWS"
      fi
    }

    # Alias to start a shell or run a command with an assumed role
    function assume-role() {
      role=${1:-${AWS_DEFAULT_PROFILE}}

      # Do not allow nested roles
      if [ -n "${AWS_VAULT}" ]; then
        echo "Type 'use-profile' to switch to another profile"
        return 1
      fi

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
        aws-google-auth ${AWS_VAULT_ARGS[@]} -p ${role} -R ${AWS_REGION} && \
        export AWS_VAULT=${role}
      else
        aws-google-auth ${AWS_VAULT_ARGS[@]} -p ${role} -R ${AWS_REGION} && \
        export AWS_VAULT=${role}
      fi
    }

    # Alias for backwards compatbility
    function use-profile() {
      export AWS_VAULT=""
      assume-role $*
    }
fi