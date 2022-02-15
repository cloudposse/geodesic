#!/bin/bash

function atmos_configure_base_path() {
	# Leave $ATMOS_BASE_PATH alone if it is already set
	if [[ -n $ATMOS_BASE_PATH ]]; then
		if [[ $SHLVL == 1 ]]; then
			green "# Using configured ATMOS_BASE_PATH of \"$ATMOS_BASE_PATH\""
		fi
		return
	fi

	# If $GEODESIC_WORKDIR contains both a "stacks" and "components" directory,
	# use it as the $ATMOS_BASE_PATH
	if [[ -d "${GEODESIC_WORKDIR}/stacks" ]] && [[ -d "${GEODESIC_WORKDIR}/components" ]]; then
		export ATMOS_BASE_PATH="${GEODESIC_WORKDIR}"
		green "# Setting ATMOS_BASE_PATH to \"$ATMOS_BASE_PATH\" based on children of workdir"
		return
	fi

	# If $GEODESIC_WORKDIR is a descendent of either a "stacks" or "components" directory,
	# use the parent of that directory as ATMOS_BASE_PATH
	if [[ "${GEODESIC_WORKDIR}" =~ /(stacks|components)/ ]]; then
		if [[ "${GEODESIC_WORKDIR}" =~ /stacks/ ]]; then
			export ATMOS_BASE_PATH="${GEODESIC_WORKDIR%/stacks/*}"
		else
			export ATMOS_BASE_PATH="${GEODESIC_WORKDIR%/components/*}"
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
