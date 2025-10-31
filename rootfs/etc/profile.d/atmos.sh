#!/bin/bash

# Configure Atmos XDG paths to use container's home directory
# This is required for Atmos auth to work correctly with mounted volumes
export ATMOS_XDG_CONFIG_HOME="${ATMOS_XDG_CONFIG_HOME:-${HOME}/.config}"
export ATMOS_XDG_DATA_HOME="${ATMOS_XDG_DATA_HOME:-${HOME}/.local/share}"
export ATMOS_XDG_CACHE_HOME="${ATMOS_XDG_CACHE_HOME:-${HOME}/.cache}"

# Helper function for Atmos auth integration
# Usage: use-identity [identity-name] [other atmos auth env flags]
# This uses Atmos auth to authenticate and set credentials in the environment
# If called with no arguments, it brings up the identity selector
function use-identity() {
	if ! command -v atmos >/dev/null 2>&1; then
		echo "Error: atmos command not found. Please install atmos first." >&2
		return 1
	fi

	# Run atmos auth env and evaluate the output to set credentials
	local auth_output
	if [ $# -eq 0 ]; then
		# No arguments: bring up the selector by passing --identity with no value
		if ! auth_output=$(atmos auth env --identity 2>&1); then
			echo "Error running atmos auth: $auth_output" >&2
			return 1
		fi
	else
		# Arguments provided: pass --identity with the first argument, then any additional flags
		if ! auth_output=$(atmos auth env --identity "$@" 2>&1); then
			echo "Error running atmos auth: $auth_output" >&2
			return 1
		fi
	fi

	# Evaluate the output to set environment variables
	eval "$auth_output"

	# If export_current_aws_role function exists (from aws.sh), refresh the AWS role display
	if declare -f export_current_aws_role >/dev/null 2>&1; then
		export_current_aws_role
	fi
}

function atmos_configure_base_path() {
	# Leave $ATMOS_BASE_PATH alone if it is already set
	if [[ -n $ATMOS_BASE_PATH ]]; then
		if [[ $SHLVL == 1 ]]; then
			green "# Using configured ATMOS_BASE_PATH of \"$ATMOS_BASE_PATH\""
		fi
		return
	fi

	# If $WORKSPACE_FOLDER contains both a "stacks" and "components" directory,
	# use it as the $ATMOS_BASE_PATH
	if [[ -d "${WORKSPACE_FOLDER}/stacks" ]] && [[ -d "${WORKSPACE_FOLDER}/components" ]]; then
		export ATMOS_BASE_PATH="${WORKSPACE_FOLDER}"
		green "# Setting ATMOS_BASE_PATH to \"$ATMOS_BASE_PATH\" based on children of workspace folder"
		return
	fi

	# If $WORKSPACE_FOLDER is a descendent of either a "stacks" or "components" directory,
	# use the parent of that directory as ATMOS_BASE_PATH
	if [[ "${WORKSPACE_FOLDER}" =~ /(stacks|components)/ ]]; then
		if [[ "${WORKSPACE_FOLDER}" =~ /stacks/ ]]; then
			export ATMOS_BASE_PATH="${WORKSPACE_FOLDER%/stacks/*}"
		else
			export ATMOS_BASE_PATH="${WORKSPACE_FOLDER%/components/*}"
		fi
		green "# Setting ATMOS_BASE_PATH to \"$ATMOS_BASE_PATH\" based on parent of workdir"
		return
	fi
	yellow "# No candidate for ATMOS_BASE_PATH found, leaving it unset"
}

# Only configure ATMOS_BASE_PATH if we find an `atmos` executable.
# Leave the function available for the user to call explicitly.
# NOTE: If we start shipping `atmos` with Geodesic by default, change this to
#   if [[ -f /usr/local/etc/atmos/atmos.yaml ]]; then
if command -v atmos >/dev/null; then
	atmos_configure_base_path
	source <(atmos completion bash) || echo error setting up atmos auto-completion
fi
