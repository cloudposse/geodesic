#!/bin/bash

export AWS_REGION_ABBREVIATION_TYPE=${AWS_REGION_ABBREVIATION_TYPE:-fixed}
export AWS_DEFAULT_SHORT_REGION=${AWS_DEFAULT_SHORT_REGION:-$(aws-region --${AWS_REGION_ABBREVIATION_TYPE} ${AWS_DEFAULT_REGION:-us-west-2})}
export GEODESIC_AWS_HOME="${GEODESIC_AWS_HOME:-/localhost/.aws}"

# `aws configure` does not respect ENVs
if [ ! -e "${HOME}/.aws" ]; then
	# -e fails if the target is a link to a non-existent file, remove dead link if it exists
	[ -L "${HOME}/.aws" ] && rm -f "${HOME}/.aws"
	if [ ! -d "${GEODESIC_AWS_HOME}" ]; then
		mkdir ${GEODESIC_AWS_HOME} && chmod 700 ${GEODESIC_AWS_HOME}
	fi
	ln -s "${GEODESIC_AWS_HOME}" "${HOME}/.aws"
fi

if [ ! -f "${AWS_CONFIG_FILE:=${GEODESIC_AWS_HOME}/config}" ] && [ -d ${GEODESIC_AWS_HOME} ]; then
	echo "# Initializing ${AWS_CONFIG_FILE}"
	# Required for AWS_PROFILE=default
	echo '[default]' >${AWS_CONFIG_FILE}
fi

# Install autocompletion rules
if command -v aws_completer >/dev/null; then
	complete -C "$(command -v aws_completer)" aws
fi

# This is the default assume-role function, but it can be overridden/replaced later
# by aws-okta or aws-vault, etc. or could have already been overridden.
if ! declare -f assume-role >/dev/null; then
	function assume-role() {
		aws_sdk_assume_role "$@"
	}
fi

function aws_choose_role() {
	_preview="${FZF_PREVIEW:-crudini --format=ini --get "$AWS_CONFIG_FILE" 'profile {}'}"
	cat "${AWS_SHARED_CREDENTIALS_FILE:-~/.aws/credentials}" "${AWS_CONFIG_FILE:-~/.aws/config}" 2>/dev/null |
		crudini --get - | sed 's/^ *profile *//' |
		fzf \
			--height 30% \
			--preview-window right:70% \
			--reverse \
			--select-1 \
			--prompt='-> ' \
			--tiebreak='begin,index' \
			--header 'Select AWS profile' \
			--query "${ASSUME_ROLE_INTERACTIVE_QUERY:-${NAMESPACE:+${NAMESPACE}-}${STAGE:+${STAGE}-}}" \
			--preview "$_preview"
}

function aws_sdk_assume_role() {
	local role=$1
	shift

	[[ -z $role && "${ASSUME_ROLE_INTERACTIVE:-true}" == "true" ]] && role=$(aws_choose_role)

	if [ -z "${role}" ]; then
		echo "Usage: assume-role <role> [command...]"
		return 1
	fi

	local assume_role="${ASSUME_ROLE}"
	ASSUME_ROLE="$role"
	if [ $# -eq 0 ]; then
		history -a # append history to file so it is available in subshell
		AWS_PROFILE="$role" bash -l
		# read history from the subshell into the parent shell
		# history -n does not work when HISTFILESIZE > HISTSIZE
		history -c
		history -r
	else
		AWS_PROFILE="$role" $*
	fi
	ASSUME_ROLE="$assume_role"
}

# Asks AWS what the currently active identity is and
# sets environment variables accordingly
function export_current_aws_role() {
	local role_name
	# Could be a primary or assumed role. If we have assumed a role, cut off the session name.
	local current_role=$(aws sts get-caller-identity --output text --query 'Arn' 2>/dev/null | cut -d/ -f1-2)
	if [[ -z $current_role ]]; then
		unset ASSUME_ROLE
		return 0
	fi

	# Quick check, are we who we say we are?
	local profile_arn
	local profile_target=${AWS_PROFILE:-${AWS_VAULT}}
	if [[ -n $profile_target ]]; then
		profile_arn=$(aws --profile "${profile_target}" sts get-caller-identity --output text --query 'Arn' 2>/dev/null | cut -d/ -f1-2)
		if [[ $profile_arn == $current_role ]]; then
			export ASSUME_ROLE="$profile_target"
			return
		fi
		echo "* $(red Profile is set to $profile_target but current role does not match:)"
		echo "*   $(red $current_role)"
		export ASSUME_ROLE=$(red '!mixed!')
		return
	fi

	# saml2aws will store the assumed role from sign-in as x_principal_arn in credentials file
	# Default values from https://awscli.amazonaws.com/v2/documentation/api/latest/topic/config-vars.html
	local creds_file="${AWS_SHARED_CREDENTIALS_FILE:-\~/.aws/credentials}"
	if [[ -r $creds_file ]]; then
		role_name=$(crudini --get --format=lines "${creds_file}" | grep "$current_role" | head -1 | cut -d' ' -f 2)
	fi

	# Assumed roles are normally found in AWS config file, but using the role ARN,
	# not the assumed role ARN. google2aws also puts login role in this file.
	local config_file="${AWS_CONFIG_FILE:-\~/.aws/config}"
	if [[ -z $role_name ]] && [[ -r $config_file ]]; then
		local role_arn=$(printf "%s" "$current_role" | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,')
		role_name=$(crudini --get --format=lines "$config_file" | grep "$role_arn" | head -1 | cut -d' ' -f 3)
	fi

	if [[ -z $role_name ]]; then
		if [[ "$role_arn" =~ "role/OrganizationAccountAccessRole" ]]; then
			role_name="$(printf "%s" "$role_arn" | cut -d: -f 5):OrgAccess"
			echo "* $(red "Could not find profile name for ${role_arn} ; calling it \"${role_name}\"")" >&2
		else
			role_name="$(printf "%s" "$role_arn" | cut -d/ -f 2)"
			echo "* $(green "Could not find profile name for ${role_arn} ; calling it \"${role_name}\"")" >&2
		fi
	fi
	export ASSUME_ROLE="$role_name"
}

# Keep track of AWS credentials and updates to AWS role environment variables.
# When changes are noticed, update prompt with current role.
unset GEODESIC_AWS_ROLE_CACHE # clear out value inherited from supershell
function refresh_current_aws_role_if_needed() {
	local is_exported="^declare -[^ x]*x[^ x]* "
	local aws_profile=$(declare -p AWS_PROFILE 2>/dev/null)
	[[ $aws_profile =~ $is_exported ]] || aws_profile=""
	local credentials_mtime=$(stat -c "%Y" ${AWS_SHARED_CREDENTIALS_FILE:-"~/.aws/credentials"} 2>/dev/null)
	local role_fingerprint="${aws_profile}/${credentials_mtime}/${AWS_ACCESS_KEY_ID}"
	if [[ $role_fingerprint != $GEODESIC_AWS_ROLE_CACHE ]]; then
		export_current_aws_role
		export GEODESIC_AWS_ROLE_CACHE="${role_fingerprint}"
	fi
}

# If OKTA or aws-vault are running, we have better hooks for keeping track of the current AWS role,
# so only use refresh_current_aws_role_if_needed if they are disabled or overridden
if [[ ($AWS_OKTA_ENABLED != "true" && ${AWS_VAULT_ENABLED:-false} != "true") || -n $AWS_PROFILE ]]; then
	PROMPT_HOOKS+=("refresh_current_aws_role_if_needed")
fi
