# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _20-localhost.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the file system mapping defined here.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file has only depends on colors.sh and should come before any scripts that
# attempt to access files on the host via `/localhost`.

if [[ $SHLVL == 1 ]] && [[ -n $GEODESIC_HOST_UID ]] && [[ -n $GEODESIC_HOST_GID ]] &&
	[[ -n $GEODESIC_LOCALHOST ]] && df -a | grep -q " ${GEODESIC_LOCALHOST}\$"; then
	if [[ $(df -a | grep ' /localhost$' | cut -f1 -d' ') == ${GEODESIC_LOCALHOST} ]]; then
		echo "# Host file ownership mapping already configured"
		export GEODESIC_LOCALHOST_MAPPED_DEVICE="${GEODESIC_LOCALHOST}"
	elif df -a | grep -q ' /localhost$'; then
		red "# Host filesystems found mounted at both /localhost and /localhost.bindfs."
		red "#  * Verify that content under /localhost is what you expect."
		red "#  * Report the issue at https://github.com/cloudposse/geodesic/issues"
		red "#  * Include the output of \`env | grep GEODESIC\` and \`df -a\` in your issue description."
	elif bindfs -o nonempty ${GEODESIC_BINDFS_OPTIONS} --create-for-user="$GEODESIC_HOST_UID" --create-for-group="$GEODESIC_HOST_GID" "${GEODESIC_LOCALHOST}" /localhost; then
		green "# BindFS mapping of ${GEODESIC_LOCALHOST} to /localhost enabled."
		green "# Files created under /localhost will have UID:GID ${GEODESIC_HOST_UID}:${GEODESIC_HOST_GID} on host."
		export GEODESIC_LOCALHOST_MAPPED_DEVICE="${GEODESIC_LOCALHOST}"
	else
		red "# ERROR: Unable to mirror /localhost.bindfs to /localhost"
		red "#  * Report the issue at https://github.com/cloudposse/geodesic/issues"
		red "#  * Work around the issue by unsetting shell environment variable GEODESIC_HOST_BINDFS_ENABLED."
		red "#  * Exiting."
		exec false
	fi
fi
