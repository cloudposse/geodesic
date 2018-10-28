set_badge() {
	if [ "${TERM_PROGRAM}" == "iTerm.app" ]; then
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
trap _exit EXIT

set_badge "${SHELL_NAME}"
