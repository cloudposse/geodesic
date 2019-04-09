# A badge is a large text label that appears in the top right of a terminal session to provide dynamic status
set_badge() {
	if [ "${TERM_PROGRAM}" == "iTerm.app" ]; then
		# https://www.iterm2.com/documentation-badges.html
		printf "\e]1337;SetBadgeFormat=%s\a" $(echo "$1" | base64)
	fi
}

## Display an exit greeting
function _exit() {
	local status=$?
	set_badge ""
	echo 'Goodbye'
	exit $status
}

# Friendly exit greeting for interactive terminals
if [ -t 1 ]; then
	trap _exit EXIT
	set_badge "${SHELL_NAME}"
fi
