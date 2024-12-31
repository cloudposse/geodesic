# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _50-workspace.sh. The leading underscore is needed to ensure this file
# executes before other files that may depend on it.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file depends on colors.sh, localhost.sh, and preferences.sh and must come after them
#

# file_on_host is true when the argument is a file or directory that appears to be on the Host file system.

function file_on_host() {
	local file
	file="$(readlink -e "$1")" || return 1
	local path
	for path in "${GEODESIC_HOST_PATHS[@]}"; do
		# Skip paths that are just slashes, or completely empty, which would match everything
		[[ "$path" =~ ^/*$ ]] && continue
		if [[ "$path" == "${file}/" || "${file}" == "$path"* ]]; then
			return 0
		fi
	done
	return 1
}

if [[ $SHLVL == 1 ]]; then
	if [[ -d ${WORKSPACE_FOLDER:=${WORKSPACE_MOUNT}} ]]; then
		green "# Initial working directory configured as ${WORKSPACE_FOLDER}"
		cd "${WORKSPACE_FOLDER}"
	else
		red "# Configured work directory ${WORKSPACE_FOLDER} does not appear to be accessible from this container"
	fi
fi
