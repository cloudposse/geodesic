# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _01-launch-warning.sh. The leading underscore is needed to ensure this file executes before
# other files with alphabetical names. The number portion is to ensure proper ordering among
# the high-priority scripts.
#
# This file has no dependencies and does not strictly need to come first,
# but it is nice to have the warnings come before other output.

# In case this output is being piped into a shell, print a warning message

# Specifically, this guards against:
#   docker run -it cloudposse/geodesic:latest-debian  | bash

# If the warning message is longer than the terminal width,
# on some terminals the message may be truncated. In that case,
# all the erasure characters will not be printed, and the message will not be erased.
# So we take pains to make the printed message appear short on the terminal.
# We do that in part by using backspaces to erase the message one character at a time,
# so the cursor never advances. Then we eval the message with backspaces removed.
# We have to then add some extra characters to erase the eval command.
function warn_if_piped() {
	local saved_stty
	saved_stty=$(stty -g)
	trap 'stty "$saved_stty"' EXIT

	stty -echo -opost

	local mesg cmd xb m fx bx feval beval
	mesg='printf "\\n\\rIf piping Geodesic output into a shell, do not attach a terminal (-t flag)\\n\\n\\r" >&2; exit 8; '
	cmd="printf \"m='\$m'; eval \\\${m//\$'\\b'/}\""

	xb=0
	m=""
	for i in $(seq 1 ${#mesg}); do
		m+="${mesg:$i-1:1}"
		[[ "${mesg:$i-1:1}" == '\' ]] && xb=$((xb + 1)) || m+=$'\b'
	done

	fx=""
	bx=""
	for i in $(seq 1 $xb); do
		bx+=$'\b'
		fx+=" "
	done
	m+=$bx
	m+=$fx
	m+=$bx

	# Cover the eval command itself. Tough to compute the exact number of backspaces needed,
	# due to escapes and non-printing characters. So we just add a few extra, because
	# extra backspaces are ignored.
	feval=$(printf "%*s" 18)
	beval="${feval// /$'\b'}"

	eval "$cmd"
	echo -n "$beval$feval$beval"

	stty "$saved_stty"
	trap - EXIT
}

warn_if_piped
unset -f warn_if_piped
