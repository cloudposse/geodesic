#!/bin/bash

function _validate_aws_vault_server() {
	[[ ${AWS_VAULT_SERVER_ENABLED:-true} == "true" ]] || return 0

	local instance
	local curl_exit_code
	instance=$(curl -m 2 --connect-timeout 0.3 -s -f http://169.254.169.254/latest/meta-data/instance-id/)
	curl_exit_code=$?

	if [[ $instance == "aws-vault" ]]; then
		_assume_active_aws_role
	elif (($curl_exit_code == 0)); then
		echo $(green force-starting aws-vault server because real AWS meta-data server is reachable)
		_force_start_aws_vault_server
	elif (($curl_exit_code == 7)) || (($curl_exit_code == 28)); then
		echo "* $(green assume-role) will start EC2 metadata service at $(green http://169.254.169.254/latest)"
		AWS_VAULT_ARGS+=("--server")
	else
		echo "* $(red Unexpected status code $curl_exit_code while probing for meta-data server. Disabling aws-vault server.)"
		export AWS_VAULT_SERVER_ENABLED="probe returned $curl_exit_code"
	fi
}

function _force_start_aws_vault_server() {
	{
		aws-vault server >/dev/null &
	} 2>/dev/null
	local aws_vault_server_pid=$!
	sleep 1
	if disown $aws_vault_server_pid 2>/dev/null; then
		echo $(green aws-vault server started at PID $aws_vault_server_pid)
		AWS_VAULT_ARGS+=("--server")
	else
		echo $(red Failed to start aws-vault server, forcing non-sever mode)
		export AWS_VAULT_SERVER_ENABLED=unavailable
	fi
}

function _assume_active_aws_role() {
	[[ ${AWS_VAULT_SERVER_ENABLED:-true} == "true" ]] || return 0

	local aws_default_profile="$AWS_DEFAULT_PROFILE"
	trap 'AWS_DEFAULT_PROFILE=${AWS_DEFAULT_PROFILE:-$aws_default_profile}' RETURN
	unset AWS_DEFAULT_PROFILE

	export TF_VAR_aws_assume_role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
	if [ -n "${TF_VAR_aws_assume_role_arn}" ]; then
		export AWS_VAULT_SERVER_EXTERNAL=true
		local aws_vault=$(crudini --get --format=lines "$AWS_CONFIG_FILE" | grep "$TF_VAR_aws_assume_role_arn" | cut -d' ' -f 3)
		if [[ -z $aws_vault ]]; then
			echo "* $(red Could not find role name for ${TF_VAR_aws_assume_role_arn}\; calling it \"instance-role\")"
			aws-vault="instance-role"
		fi
		if [[ -z $AWS_VAULT || $AWS_VAULT == $aws_vault ]]; then
			echo "* $(green Attaching to exising aws-vault session and assuming role) $(cyan ${aws_vault})"
			export AWS_VAULT="$aws_vault"
			export ASSUME_ROLE=${AWS_VAULT}
			export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION-${AWS_REGION}}"
		fi
	else
		unset TF_VAR_aws_assume_role_arn
		AWS_DEFAULT_PROFILE=${aws_default_profile}
		AWS_VAULT_SERVER_ENABLED="get-caller-identity failed"
	fi
}

if [ "${AWS_VAULT_ENABLED:-true}" == "true" ]; then
	if ! which aws-vault >/dev/null; then
		echo "aws-vault not installed"
		exit 1
	fi

	if [ -n "${AWS_VAULT}" ]; then
		export ASSUME_ROLE=${AWS_VAULT}
		# Set the Terraform `aws_assume_role_arn` based on our current context
		export TF_VAR_aws_assume_role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
		if [ -n "${TF_VAR_aws_assume_role_arn}" ]; then
			echo "* Assumed role $(green ${TF_VAR_aws_assume_role_arn})"
		else
			echo "* $(red Assume role failed)"
			exit 1
		fi
	else
		AWS_VAULT_ARGS=()
		AWS_VAULT_ARGS+=("--assume-role-ttl=${AWS_VAULT_ASSUME_ROLE_TTL}")
		AWS_VAULT_ARGS+=("--session-ttl=${AWS_VAULT_SESSION_TTL}")

		[ -d /localhost/.awsvault ] || mkdir -p /localhost/.awsvault
		ln -sf /localhost/.awsvault ${HOME}
		if [ "${AWS_VAULT_SERVER_ENABLED:-true}" == "true" ]; then
			_validate_aws_vault_server
		fi
	fi

	PROMPT_HOOKS+=("aws_vault_prompt")
	function aws_vault_prompt() {
		if [ -z "${AWS_VAULT}" ]; then
			echo -e "-> Run '$(green assume-role)' to login to AWS with aws-vault"
		fi
	}

	function choose_role_interactive() {
		_preview="${FZF_PREVIEW:-crudini --format=ini --get "$AWS_CONFIG_FILE" 'profile {}'}"
		crudini --get "${AWS_CONFIG_FILE}" |
			awk -F ' ' '{print $2}' |
			fzf \
				--height 30% \
				--preview-window right:70% \
				--reverse \
				--select-1 \
				--prompt='-> ' \
				--header 'Select AWS profile' \
				--query "${ASSUME_ROLE_INTERACTIVE_QUERY:-${NAMESPACE}-${STAGE}-}" \
				--preview "$_preview"
	}

	function choose_role() {
		if [ "${ASSUME_ROLE_INTERACTIVE:-true}" == "true" ]; then
			echo "$(choose_role_interactive)"
		else
			echo "${AWS_DEFAULT_PROFILE}"
		fi
	}

	# Start a shell or run a command with an assumed role
	function aws_vault_assume_role() {
		# Do not allow nested roles
		if [ -n "${AWS_VAULT}" ]; then
			# There is an exception to the "Do not allow nested roles" rule.
			# If we are in the current role because we are piggybacking off of an aws-vault credential server
			# started by another process, then it is safe to allow "nesting" because we are not really in
			# an aws-vault shell to start with. We have to allow this (a) in order to assume a role other
			# than the one the credential server is serving and (b) to continue to be able to work if
			# the process that started the server ends and takes the credential server with it.
			if [ "$SHLVL" -eq 1 ] && [ "${AWS_VAULT_SERVER_ENABLED:-true}" == "true" ]; then
				# Save the current values of AWS_VAULT and AWS_VAULT_SERVER_ENABLED
				local aws_vault="$AWS_VAULT"
				local aws_vault_server_enabled="${AWS_VAULT_SERVER_ENABLED:-true}"
				# Be sure to restore the values of AWS_VAULT and AWS_VAULT_SERVER_ENABLED when
				# this function returns, regardless of how it returns (e.g. in case of errors).
				trap 'export AWS_VAULT="$aws_vault" && export AWS_VAULT_SERVER_ENABLED="$aws_vault_server_enabled"' RETURN
				unset AWS_VAULT
				AWS_VAULT_SERVER_ENABLED=false
			else
				echo "Type '$(green exit)' before attempting to assume another role"
				return 1
			fi
		fi

		role=${1:-$(choose_role)}

		if [ -z "${role}" ]; then
			echo "Usage: assume-role [role]"
			return 1
		fi

		if [ "${DOCKER_TIME_DRIFT_FIX:-true}" == "true" ]; then
			# Use a timeout due to slow clock reads on EC2 (10 seconds).
			# Fixes: hwclock: select() to /dev/rtc0 to wait for clock tick timed out
			hwclock_time=$(timeout 1.5 hwclock -r)

			# Sync the clock in the Docker Virtual Machine to the system's hardware clock to avoid time drift.
			# Assume whichever clock is behind by more than 10 seconds is wrong, since virtual clocks
			# almost never gain time.
			if [ -n "${hwclock_time}" ]; then
				let diff=$(date '+%s')-$(date -d "${hwclock_time}" '+%s')
				if [ $diff -gt 10 ]; then
					hwclock -w >/dev/null 2>&1
				elif [ $diff -lt -10 ]; then
					# (Only works in privileged mode)
					hwclock -s >/dev/null 2>&1
				fi
				if [ $? -ne 0 ]; then
					echo "* $(yellow Failed to sync system time from hardware clock)"
				fi
			fi
		fi

		shift
		if [ $# -eq 0 ]; then
			aws-vault exec ${AWS_VAULT_ARGS[@]} $role -- bash -l
		else
			aws-vault exec ${AWS_VAULT_ARGS[@]} $role -- $*
		fi
	}

	function assume-role() {
		aws_vault_assume_role $*
	}
fi
