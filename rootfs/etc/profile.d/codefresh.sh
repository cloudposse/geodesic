#!/bin/bash
# Tools for use specifically within the Codefresh CI/CD pipeline

# Usage:
#    require_cfvar '${{VARNAME}}' [documentation of the variable]
#
# Returns true (exit 0) if ${{VARNAME}} has been replaced with something else, indicating it has been set.
# Returns false and echos "VARNAME: documentation of the variable" if ${{VARNAME}} has not been set.
# Note that the single quotes around ${{VARNAME}} are critical.
function require_cfvar() {
	# Look for ${{VARNAME}}
	local left=$(expr index "$1" '${{')
	local right=$(expr index "$1" '}}')
	(( $left > 0 && $right > 0 )) || return 0

	# Extract VARNAME
	let left+=3
	local var=$(expr substr "$1" $left $(( $right - $left )))
	echo Build variable \"$var\" has not been set >&2

	# Look for docmentation of VARNAME on the rest of the args
	# First, look for trailing characters on $1 and collect them
	let right++
	local rem1="${1:$right}"

	shift
	local doc="$rem1 $*"
	# remove leading spaces
	doc="${doc:$(expr match "$doc" '\s*')}"

	(( ${#doc} > 0 )) && echo "${var}: $doc"

	return 3
}


# Usage:
#    require_cfvars <<'EOF'
#    ${{VAR_ONE}} documentation of VAR_ONE
#    ${{VAR_TWO}} documentation of VAR_TWO
#    ...
#    EOF
# Checks each variable with require_cfvar.
# Variables must be at the start of the line, one per line, but do not need to be quoted.
# The final EOF must be at the begining of the line.
function require_cfvars() {
	local v
	while read v; do
		echo "${v@Q}"
		require_cfvar "$v"
	done
}
