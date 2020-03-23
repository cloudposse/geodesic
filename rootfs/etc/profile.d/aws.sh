if [ ! -d "${AWS_DATA_PATH}" ]; then
	echo "* Initializing ${AWS_DATA_PATH}"
	mkdir -p "${AWS_DATA_PATH}"
fi

# `aws configure` does not respect ENVs
if [ ! -e "${HOME}/.aws" ]; then
	ln -s "${AWS_DATA_PATH}" "${HOME}/.aws"
fi

if [ ! -f "${AWS_CONFIG_FILE}" ]; then
	echo "* Initializing ${AWS_CONFIG_FILE}"
	# Required for AWS_PROFILE=default
	echo '[default]' >${AWS_CONFIG_FILE}
fi

# Install autocompletion rules
if which aws_completer >/dev/null; then
	complete -C "$(which aws_completer)" aws
fi

# Asks AWS what the currently active identity is and
# sets environment variables accordingly
function export_current_aws_role() {
	local role_arn=$(aws sts get-caller-identity --output text --query 'Arn' | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,' | cut -d/ -f1-2)
	if [[ -n $role_arn ]]; then
		export DETECTED_ROLE_ARN="$role_arn"
		local role_name=$(crudini --get --format=lines "$AWS_CONFIG_FILE" | grep "$role_arn" | cut -d' ' -f 3)
		if [[ -z role_name ]]; then
			echo "* $(red Could not find role name for ${role_arn}\; calling it \"unknown-role\")"
			role_name="unknown-role"
		fi
		export ASSUME_ROLE="$role_name"
	fi
}

# Keep track of AWS credentials and updates AWS role environment variables
# when it notices changes
function refresh_current_aws_role_if_needed() {
	local credentials_mtime=$(stat -c "%Y" ${AWS_SHARED_CREDENTIALS_FILE:-"~/.aws/credentials"} 2>/dev/null)
	local role_fingerprint="${AWS_PROFILE}/${credentials_mtime}/${AWS_ACCESS_KEY_ID}"
	if [[ $role_fingerprint != $CURRRENT_AWS_ROLE_CACHE ]]; then
		export_current_aws_role
		export CURRRENT_AWS_ROLE_CACHE="${role_fingerprint}"
	fi
}

# If OKTA oar aws-vault are running, we have better hooks for keeping track of
# the current AWS role, so only use refresh_current_aws_role_if_needed if they are disabled
if [[ $AWS_OKTA_ENABLED != "true" ]] && [[ ${AWS_VAULT_ENABLED:-true} != "true" ]] ; then
	PROMPT_HOOKS+=("refresh_current_aws_role_if_needed")
fi