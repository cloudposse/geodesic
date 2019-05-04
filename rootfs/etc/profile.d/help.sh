# Use `man` page system for help
function help() {
	if [ $# -ne 0 ]; then
		apropos "$*"
	else
		echo -e "Available documentation:\n\n"
		apropos . | sed 's/^/  /'
	fi
}
