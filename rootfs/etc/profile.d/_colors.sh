# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _colors.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the functions defined here. This file has no dependencies and should come first.
function red() {
	echo "$(tput setaf 1)$*$(tput sgr0)"
}

function green() {
	echo "$(tput setaf 2)$*$(tput sgr0)"
}

function yellow() {
	echo "$(tput setaf 3)$*$(tput sgr0)"
}

function cyan() {
	echo "$(tput setaf 6)$*$(tput sgr0)"
}
