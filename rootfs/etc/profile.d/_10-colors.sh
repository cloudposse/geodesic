# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _10-colors.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the functions defined here. The number portion is to ensure proper ordering among
# the high-priority scripts
# This file has no dependencies and should come first.
function red() {
	echo "$(tput setaf 1)$*$(tput setaf 0)"
}

function green() {
	echo "$(tput setaf 2)$*$(tput setaf 0)"
}

function yellow() {
	echo "$(tput setaf 3)$*$(tput setaf 0)"
}

function cyan() {
	echo "$(tput setaf 6)$*$(tput setaf 0)"
}

# Turning on bold is a standard `tput` attribute, but turning it off is not.
# However, turning off bold is an ECMA standard (SGR 22), so it is not
# unreasonable for us to use it. If it causes problems, people can set
#   export TERM_BOLD_OFF=$(tput sgr0)
# http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-048.pdf
function bold() {
	local bold=$(tput bold)
	local boldoff=${TERM_BOLD_OFF:-$'\033[22m'}
	# If the terminal supports color
	if [[ -n $bold ]]; then
		printf "%s%s%s\n" "$bold" "$*" "$boldoff"
	else
		# The terminal does not support color
		printf "%s\n" "$*"
	fi
}
