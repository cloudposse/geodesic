#!/usr/bin/env bash

if [ "${AWS_OKTA_ENABLED}" == "true" ]; then
	if ! which aws-okta >/dev/null; then
		echo "aws-okta not installed"
		exit 1
	fi

	if [ -n "${AWS_OKTA_PROFILE}" ]; then
		export ASSUME_ROLE=${AWS_OKTA_PROFILE}
		# Set the Terraform `aws_assume_role_arn` based on our current context
		export TF_VAR_aws_assume_role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
		echo
		echo "* Assumed role $(green ${TF_VAR_aws_assume_role_arn})"
	else
		AWS_VAULT_ARGS=("--assume-role-ttl=${AWS_VAULT_ASSUME_ROLE_TTL}")
		[ -d /localhost/.aws-okta ] || mkdir -p /localhost/.aws-okta
		ln -sf /localhost/.aws-okta ${HOME}
	fi

	PROMPT_HOOKS+=("aws_okta_prompt")
	function aws_okta_prompt() {
		if [ -z "${AWS_OKTA_PROFILE}" ]; then
			echo -e "-> Run '$(green assume-role)' to login to AWS with aws-okta"
		fi
	}

	# Alias to start a shell or run a command with an assumed role
	function aws_okta_assume_role() {
		role=${1:-${AWS_DEFAULT_PROFILE}}

		# Do not allow nested roles
		if [ -n "${AWS_OKTA_PROFILE}" ]; then
			echo "Type '$(green exit)' before attempting to assume another role"
			return 1
		fi

		if [ -z "${role}" ]; then
			echo "Usage: assume-role [role]"
			return 1
		fi
		# Sync the clock in the Docker Virtual Machine to the system's hardware clock to avoid time drift
		# (Only works in privileged mode)
		hwclock -s >/dev/null 2>&1
		if [ $? -ne 0 ]; then
			echo "* $(yellow Failed to sync system time from hardware clock)"
		fi

		shift
		if [ $# -eq 0 ]; then
			aws-okta exec ${AWS_OKTA_ARGS[@]} $role -- bash -l
		else
			aws-okta exec ${AWS_OKTA_ARGS[@]} $role -- $*
		fi
	}

	function assume-role() {
		aws_okta_assume_role $*
	}
fi
