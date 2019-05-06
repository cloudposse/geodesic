# Use `man` page system for help
function help() {
	if [ $# -ne 0 ]; then
		docs search --query="$*"
	else
		docs search
	fi
}
