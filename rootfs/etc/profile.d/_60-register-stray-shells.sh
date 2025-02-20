# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _50-workspace.sh. The leading underscore is needed to ensure this file
# executes before other files that may depend on it.
# The number portion is to ensure proper ordering among the high-priority scripts.

# This file depends on colors for colored output and must come after it.

# We track shells launched by `docker exec` so that we can shut down the container when they exit,
# and so that we can signal them to quit when the container is shutting down.
#
# The wrapper script that launches the shell sets the environment variable `G_HOST_PID` to the PID of the
# shell process launching the shell, so it can track it when it exist.
#
# This script detects shells launched outside the wrapper and gives them a G_HOST_PID=0 so that they get tracked.
#

# If the parent process ID ($PPID) is zero (0), then this shell was launched by Docker exec.
# If $$ = 1, then it was the shell launched when the container started, and we do not need to track it.

if [[ $$ != 1 ]] && [[ $PPID == 0 ]] && [[ -z $G_HOST_PID ]]; then
	export G_HOST_PID=0
	[[ -t 0 ]] && yellow '# Detected shell launched by `docker exec` without wrapper info, tracking as stray shell.'
fi
