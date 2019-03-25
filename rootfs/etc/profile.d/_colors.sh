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
