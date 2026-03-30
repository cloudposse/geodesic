#!/bin/bash
# shellcheck disable=SC2155
# Above directive suppresses ShellCheck SC2155: Declare and assign separately to avoid masking return values.
# In this script, we do not care about return values, as problems are detected by the resulting empty value.

export AWS_REGION_ABBREVIATION_TYPE=${AWS_REGION_ABBREVIATION_TYPE:-fixed}
export AWS_DEFAULT_SHORT_REGION=${AWS_DEFAULT_SHORT_REGION:-$(aws-region --"${AWS_REGION_ABBREVIATION_TYPE}" "${AWS_DEFAULT_REGION:-us-west-2}")}
export GEODESIC_AWS_HOME

# _aws_config_home locates or creates the AWS configuration directory, exports GEODESIC_AWS_HOME (and may set AWS_CONFIG_FILE), ensures the directory and config file exist with secure permissions, and returns 1 on failure to create a usable directory.
function _aws_config_home() {
	for dir in "${GEODESIC_AWS_HOME}" "${LOCAL_HOME}/.aws" "${HOME}/.aws"; do
		if [ -d "${dir}" ]; then
			GEODESIC_AWS_HOME="${dir}"
			break
		fi
	done

	if [ -z "${GEODESIC_AWS_HOME}" ]; then
		yellow "# No AWS configuration directory found, using ${HOME}/.aws"
		GEODESIC_AWS_HOME="${HOME}/.aws"
	fi

	if [ ! -d "${GEODESIC_AWS_HOME}" ]; then
		if ! mkdir "${GEODESIC_AWS_HOME}"; then # allow error message to be printed
			local first_try="${GEODESIC_AWS_HOME}"
			export GEODESIC_AWS_HOME="${HOME}/.aws"
			if mkdir "${GEODESIC_AWS_HOME}"; then
				if [ -n "${AWS_CONFIG_FILE}" ] && [ ! -f "${AWS_CONFIG_FILE}" ]; then
					AWS_CONFIG_FILE="${GEODESIC_AWS_HOME}/config"
				fi
			else
				red "# Could not use ${first_try}, or ${GEODESIC_AWS_HOME} for AWS configuration, giving up."
				return 1
			fi
		fi
		chmod 700 "${GEODESIC_AWS_HOME}"
	fi

	if [ ! -f "${AWS_CONFIG_FILE:=${GEODESIC_AWS_HOME}/config}" ] && [ -d "${GEODESIC_AWS_HOME}" ]; then
		echo "# Initializing ${AWS_CONFIG_FILE}"
		# Required for AWS_PROFILE=default
		echo '[default]' >"${AWS_CONFIG_FILE}"
		chmod 600 "${AWS_CONFIG_FILE}"
	fi
}

_aws_config_home
unset -f _aws_config_home

# Install autocompletion rules for aws CLI v1 and v2
for __aws in aws aws1 aws2; do
	if command -v ${__aws}_completer >/dev/null; then
		complete -C "$(command -v ${__aws}_completer)" ${__aws}
	fi
done
unset __aws

# This is the default assume-role function, but it can be overridden/replaced later
# by aws-okta or aws-vault, etc. or could have already been overridden.
if ! declare -f assume-role >/dev/null; then
	function assume-role() {
		aws_sdk_assume_role "$@"
	}
fi

function aws_choose_role() {
	_preview="${FZF_PREVIEW:-crudini --format=ini --get "$AWS_CONFIG_FILE" 'profile {}'}"
	cat "${AWS_SHARED_CREDENTIALS_FILE:-${GEODESIC_AWS_HOME}/credentials}" "${AWS_CONFIG_FILE:-${GEODESIC_AWS_HOME}/config}" 2>/dev/null |
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

# Usage: aws_sdk_assume_role <role> [command...]
# aws_sdk_assume_role sets ASSUME_ROLE and AWS_PROFILE to the specified role (or an interactively chosen role if none specified) and either launches a login subshell that preserves shell history or executes a given command with that profile, then restores the previous ASSUME_ROLE.
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
		AWS_PROFILE="$role" "$@"
	fi
	ASSUME_ROLE="$assume_role"
}

# Asks AWS what the currently active identity is and
# export_current_aws_role sets ASSUME_ROLE to reflect the currently active AWS identity.
# It inspects the current STS caller identity and the active profile (AWS_PROFILE or AWS_VAULT),
# attempts to map the active ARN to a more descriptive profile name by consulting the AWS config
# and credentials files (handling normal IAM roles and Identity Center/SSO roles), warns and
# exports a redacted marker when the environment profile disagrees with the active identity,
# and unsets ASSUME_ROLE and returns when no identity can be determined.
function export_current_aws_role() {
	local role_name role_names
	# Could be a primary or assumed role. If we have assumed a role, cut off the session name.
	local current_role=$(aws sts get-caller-identity --output text --query 'Arn' 2>/dev/null | cut -d/ -f1-2)
	if [[ -z $current_role ]]; then
		unset ASSUME_ROLE
		return 0
	fi

	# If AWS_VAULT is not enabled, clear any setting from it.
	[[ "${AWS_VAULT_ENABLED:-false}" == "true" ]] || unset AWS_VAULT

	# Quick check, are we who we say we are? Does the current role match the profile?
	local profile_arn
	local profile_target=${AWS_PROFILE:-${AWS_VAULT:-default}}
	# Remove the session name from the profile target role, if present
	profile_arn=$(aws --profile "${profile_target}" sts get-caller-identity --output text --query 'Arn' 2>/dev/null | cut -d/ -f1-2)
	# The main way there would be a mismatch is if AWS_VAULT is set or there are API keys in the environment
	if [[ "$profile_arn" == "$current_role" ]]; then
		# If we are here, then the current role matches the assigned profile. That is a good thing.
		# However, the profile name may not be the best name for the role. If it is too generic, try to find a better name.
		# Extract profile name from config file:
		# 1. For default profile, look for a better name
		# 2. Skip identity profiles (ending with -identity), as they are too generic
		# 3. Use the first non-default, non-identity profile found
		if [[ $profile_target == "default" ]] || [[ $profile_target =~ -identity$ ]]; then
			local backup_name="$profile_target"
			# Make some effort to find a better name for the role, but only check the config file, not credentials.
			local config_file="${AWS_CONFIG_FILE:-${GEODESIC_AWS_HOME}/config}"
			if [[ -r $config_file ]]; then
				# Is this a normal IAM role or an Identity Center permissions set role?
				if [[ $current_role =~ AWSReservedSSO_[^_]+_[0-9a-f]+$ ]]; then
					# This is an Identity Center permissions set role
					# current_role is "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_IdentityAdminRoleAccess_5c90026c17fbd1c2"

					# Extract account ID using cut
					local account_id=$(echo "$current_role" | cut -d':' -f5)

					# Extract the full role part
					local role_part=$(echo "$current_role" | cut -d':' -f6) # This gets everything after the 5th colon

					# Extract the role name by isolating it from boilerplate
					local sso_role_name=$(echo "$role_part" | cut -d'_' -f2) # This selects the second field delimited by '_'

					# Find all profiles that have matching role names
					local profile_names
					mapfile -t profile_names < <(crudini --get --format=lines "$config_file" | grep "$sso_role_name" | cut -d' ' -f 3)
					local profile_name
					for profile_name in "${profile_names[@]}"; do
						# Skip the generic profiles
						if [[ "$profile_name" == "default" ]] || [[ "$profile_name" =~ -identity$ ]]; then
							continue
						fi
						if [[ "$account_id" == "$(crudini --get "$config_file" "profile $profile_name" sso_account_id)" ]]; then
							export ASSUME_ROLE="$profile_name"
							return
						fi
					done
					export ASSUME_ROLE="$backup_name"
					return
				fi

				# Normal IAM role
				# Assumed roles in AWS config file use the role ARN, not the assumed role ARN, so adjust accordingly.
				local role_arn=$(printf "%s" "$current_role" | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,')
				mapfile -t role_names < <(crudini --get --format=lines "$config_file" | grep "$role_arn" | cut -d' ' -f 3)
				for rn in "${role_names[@]}"; do
					if [[ $rn == "default" ]] || [[ $rn =~ -identity$ ]]; then
						continue
					else
						export ASSUME_ROLE=$rn
						return
					fi
				done
			fi
		fi
		# could not find a better match, so just use the generic profile name
		export ASSUME_ROLE="$profile_target"
		return
	fi

	# If we are here, then the current role is not what we would expect from the AWS_PROFILE setting.
	# If AWS_PROFILE is unset, then we forgive the current role not being the default role.
	# Otherwise, we warn about a mismatch.
	if [[ -n $AWS_PROFILE ]]; then
		red "* AWS Credentials Mismatch! AWS_PROFILE is set to $AWS_PROFILE"
		red "* That profile selects role $profile_arn"
		red "* But STS reports current role is $current_role"
		export ASSUME_ROLE=$(red-n '!mixed!')
		return
	elif [[ -n $AWS_VAULT ]]; then
		red "* AWS Credentials Mismatch! AWS_VAULT claims to have set role to profile $AWS_VAULT"
		red "* That profile selects role $profile_arn"
		red "* But STS reports current role is $current_role"
		red "* "
		export ASSUME_ROLE=$(red-n '!mixed!')
		return
	fi

	# If we are here, then we are not using AWS_VAULT or AWS_PROFILE, and the current role does not match the default profile.
	# This is likely because we are using API keys directly in the environment or credentials file.
	# Try to figure out a better name for the role.

	# saml2aws will store the assumed role from sign-in as x_principal_arn in credentials file
	# Default values from https://awscli.amazonaws.com/v2/documentation/api/latest/topic/config-vars.html
	local creds_file="${AWS_SHARED_CREDENTIALS_FILE:-${GEODESIC_AWS_HOME}/credentials}"
	if [[ -r $creds_file ]]; then
		role_name=$(crudini --get --format=lines "${creds_file}" | grep "$current_role" | head -1 | cut -d' ' -f 2)
	fi

	# Assumed roles are normally found in AWS config file, but using the role ARN,
	# not the assumed role ARN. google2aws also puts login role in this file.
	local config_file="${AWS_CONFIG_FILE:-${GEODESIC_AWS_HOME}/config}"
	if [[ -z $role_name ]] && [[ -r $config_file ]]; then
		local role_arn=$(printf "%s" "$current_role" | sed 's/:sts:/:iam:/g' | sed 's,:assumed-role/,:role/,')
		role_name=$(crudini --get --format=lines "$config_file" | grep "$role_arn" | head -1 | cut -d' ' -f 3)
	fi

	# If we still don't have a profile name, make one up.
	if [[ -z $role_name ]]; then
		if [[ "$role_arn" =~ "role/OrganizationAccountAccessRole" ]]; then
			role_name="$(printf "%s" "$role_arn" | cut -d: -f 5):OrgAccess"
		elif [[ $current_role =~ AWSReservedSSO_[^_]+_[0-9a-f]+$ ]]; then
			# This is an Identity Center permissions set role
			# current_role is "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_IdentityAdminRoleAccess_5c90026c17fbd1c2"
			# Extract account ID using cut
			local account_id=$(echo "$current_role" | cut -d':' -f5)
			# Extract the full role part
			local role_part=$(echo "$current_role" | cut -d':' -f6) # This gets everything after the 5th colon
			# Extract the role name by isolating it from boilerplate
			local sso_role_name=$(echo "$role_part" | cut -d'_' -f2) # This selects the second field delimited by '_'
			role_name="${account_id}:${sso_role_name}"
		else
			role_name="$(printf "%s" "$role_arn" | cut -d/ -f 2)"
		fi
		echo "* $(green "Could not find profile name for ${role_arn} ; calling it \"${role_name}\"")" >&2
	fi
	export ASSUME_ROLE="$role_name"
}

# Keep track of AWS credentials and updates to AWS role environment variables.
# When changes are noticed, update prompt with current role.
unset GEODESIC_AWS_ROLE_CACHE # refresh_current_aws_role_if_needed checks whether the active AWS role context has changed and updates cached state if necessary.
# 
# It computes a fingerprint from the exported AWS_PROFILE, the modification time of the shared credentials file, and AWS_ACCESS_KEY_ID; if the fingerprint differs from GEODESIC_AWS_ROLE_CACHE it calls export_current_aws_role and updates GEODESIC_AWS_ROLE_CACHE with the new fingerprint.
function refresh_current_aws_role_if_needed() {
	local is_exported="^declare -[^ x]*x[^ x]* "
	local aws_profile=$(declare -p AWS_PROFILE 2>/dev/null)
	[[ $aws_profile =~ $is_exported ]] || aws_profile=""
	local credentials_mtime=$(stat -c "%Y" "${AWS_SHARED_CREDENTIALS_FILE:-${GEODESIC_AWS_HOME}/credentials}" 2>/dev/null)
	local role_fingerprint="${aws_profile}/${credentials_mtime}/${AWS_ACCESS_KEY_ID}"
	if [[ $role_fingerprint != "$GEODESIC_AWS_ROLE_CACHE" ]]; then
		export_current_aws_role
		export GEODESIC_AWS_ROLE_CACHE="${role_fingerprint}"
	fi
}

# If OKTA or aws-vault are running, we have better hooks for keeping track of the current AWS role,
# so only use refresh_current_aws_role_if_needed if they are disabled or overridden
if [[ ($AWS_OKTA_ENABLED != "true" && ${AWS_VAULT_ENABLED:-false} != "true") || -n $AWS_PROFILE ]]; then
	PROMPT_HOOKS+=("refresh_current_aws_role_if_needed")
fi