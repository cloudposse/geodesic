# A badge is a large text label that appears in the top right of a terminal session to provide dynamic status
if [ "${TERM_PROGRAM}" == "iTerm.app" ]; then
	# https://www.iterm2.com/documentation-badges.html
	printf "\e]1337;SetBadgeFormat=%s\a" $(printf "%s" "${SHELL_NAME}" | base64)

	## Display an exit greeting
	function _geodesic_iterm_exit() {
		local status=$?
		# Clear the badge
		printf "\e]1337;SetBadgeFormat=\a"
		echo 'Goodbye'
		exit $status
	}

	# Friendly exit greeting for interactive terminals, if exit trap not already set
	if [[ -t 1 ]] && [[ -z "$(trap -p exit)" ]]; then
		trap _geodesic_iterm_exit EXIT
	fi
fi
