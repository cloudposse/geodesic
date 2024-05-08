# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _10-colors.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the functions defined here. The number portion is to ensure proper ordering among
# the high-priority scripts.
#
# This file depends on _07-term-mode.sh and should come second.

# This file provides functions to colorize text in the terminal.
# It has moderate support for light and dark mode, but it is not perfect.
# The main change is that it uses the terminal's default colors for foreground and background,
# whereas the previous version "reset" the color by setting it to black, which fails in dark mode.

function update-terminal-mode() {
	local new_mode="$1"
	case $new_mode in
	dark | light) ;;

	"")
		new_mode=$(_is_term_dark_mode -mm)
		;;

	*)
		echo "Usage: update-terminal-mode [dark|light]" >&2
		return 1
		;;
	esac

	if [[ $new_mode == "unknown" ]]; then
		if ! tty -s; then
			echo "No terminal detected." >&2
		elif [[ -z "$(tput op 2>/dev/null)" ]]; then
			echo "Terminal does not appear to support color." >&2
		fi
		new_mode="light"
	fi

	# See comments in _geodesic_color() below for why we test ${_geodesic_tput_cache@a}
	if [[ ${_geodesic_tput_cache@a} != "A" ]] ||
		[[ "${_geodesic_tput_cache[dark_mode]}" != "$new_mode" ]] ||
		[[ "${_geodesic_tput_cache[TERM]}" != "$TERM" ]]; then
		_geodesic_tput_cache_init "$1"
	else
		echo "Not updating terminal mode from $new_mode to $new_mode"
	fi
}

# We call `tput` several times for every prompt, and it can add up, so we cache the results.
function _geodesic_tput_cache_init() {
	declare -g -A _geodesic_tput_cache
	local old_term=${_geodesic_tput_cache[TERM]}
	# Save the terminal type so we can invalidate the cache if it changes
	_geodesic_tput_cache[TERM]="$TERM"

	local color_off=$(tput op 2>/dev/null) # reset foreground and background colors to defaults

	if ! tty -s || [[ -z $color_off ]]; then
		if [[ $GEODESIC_TRACE =~ "terminal" ]]; then
			if ! tty -s; then
				echo '* TERMINAL TRACE: Not running in a terminal, not attempting to colorize output' >&2
			elif [[ -z $color_off ]]; then
				echo '* TERMINAL TRACE: `tput` did not output anything for "op", not attempting to colorize output' >&2
			else
				echo '* TERMINAL TRACE: Unknown error (script bug), not attempting to colorize output' >&2
			fi
		fi
		if [[ $old_term != ${_geodesic_tput_cache[TERM]} ]]; then
			_geodesic_generate_color_functions dummy
			command -V geodesic_prompt_style &>/dev/null && geodesic_prompt_style
		fi
		return 1
	fi

	# If we are here, we have lost the terminal mode settings.
	# If we are not in a subshell, we are fixing them now.
	# However, if we are in a subshell, we cannot fix them in the main shell
	# from here, so we need to tell the user to run the command to fix them.
	if [[ $BASH_SUBSHELL != 0 ]]; then
		printf "\n* Terminal mode settings have been lost (%s,%s).\n" "$SHLVL" "$BASH_SUBSHELL" >&2
		printf "* Please run: update-terminal-mode \n\n" >&2
	fi

	local bold=$(tput bold)
	local bold_off

	if [[ -n "$bold" ]]; then
		# Turning on bold is a standard `tput` attribute, but turning it off is not.
		# However, turning off bold is an ECMA standard (SGR 22), so it is not
		# unreasonable for us to use it. If it causes problems, people can set
		#   export TERM_BOLD_OFF=$(tput sgr0)
		# http://www.ecma-international.org/publications/files/ECMA-ST/Ecma-048.pdf
		bold_off=${TERM_BOLD_OFF:-$'\033[22m'}
	fi

	# Set up normal colors for light mode
	_geodesic_tput_cache=(
		[TERM]="$TERM"
		[black]=$(tput setaf 0)
		[red]=$(tput setaf 1)
		[green]=$(tput setaf 2)
		[yellow]=$(tput setaf 3)
		[blue]=$(tput setaf 4)
		[magenta]=$(tput setaf 5)
		[cyan]=$(tput setaf 6)
		[white]=$(tput setaf 7)
	)

	local new_mode="$1"
	case $new_mode in
	dark | light) ;;

	"")
		new_mode=$(_is_term_dark_mode -m)
		;;

	*)
		echo "Usage: _geodesic_tput_cache_init [dark|light]" >&2
		# Proceed with automatic detection to avoid
		# repeated reinitializations.
		new_mode=$(_is_term_dark_mode -m)
		;;
	esac

	if [[ $new_mode == "dark" ]]; then
		_geodesic_tput_cache[black]=$(tput setaf 7)              # swap black and white
		_geodesic_tput_cache[white]=$(tput setaf 0)              # 0 is ANSI black, 7 is ANSI white
		_geodesic_tput_cache[blue]=${_geodesic_tput_cache[cyan]} # blue is too dark, use cyan instead
	else
		_geodesic_tput_cache[yellow]=${_geodesic_tput_cache[magenta]} # yellow is too light, use magenta instead
	fi

	local key
	for key in "${!_geodesic_tput_cache[@]}"; do
		if [[ -n ${_geodesic_tput_cache["$key"]} ]]; then
			# Note, we cannot use printf for "-off" because command substitution strips trailing newlines
			_geodesic_tput_cache["${key}-off"]="$color_off"$'\n'
			_geodesic_tput_cache["bold-${key}"]=$(printf "%s%s" "$bold" "${_geodesic_tput_cache["$key"]}")
			_geodesic_tput_cache["bold-${key}-off"]="${color_off}${bold_off}"$'\n'

			# Note $'\x01' and $'\x02' are ASCII codes to put around non-printing characters so that
			# bash can correctly calculate the visible length of the string.
			# They are equivalent to \[ and \] in a bash prompt string.
			# Also note that these variants do not include a newline at the end.
			_geodesic_tput_cache["${key}-n"]=$(printf "\x01%s\x02" "${_geodesic_tput_cache["$key"]}")
			_geodesic_tput_cache["${key}-n-off"]=$(printf "\x01%s\x02" "$color_off")
			_geodesic_tput_cache["bold-${key}-n"]=$(printf "\x01%s%s\x02" "$bold" "${_geodesic_tput_cache["$key"]}")
			_geodesic_tput_cache["bold-${key}-n-off"]=$(printf "\x01%s%s\x02" "$color_off" "$bold_off")
		fi
	done

	# Bold is not a color, handle bold without color change separately
	if [[ -n "$bold"} ]]; then
		_geodesic_tput_cache["bold"]=$(printf "\x01%s\x02" "$bold")
		_geodesic_tput_cache["bold-off"]=$(printf "\x01%s\x02" "$bold_off")
	fi

	_geodesic_tput_cache[dark_mode]="$new_mode"
	if [[ $old_term != ${_geodesic_tput_cache[TERM]} ]]; then
		_geodesic_generate_color_functions color
		command -V geodesic_prompt_style &>/dev/null && geodesic_prompt_style
	fi
}

# Colorize text using ANSI escape codes.
# Usage: _geodesic_color style text...
# `style` is defined by the keys of the associative array _geodesic_tput_cache set up above.
# Not intended to be called directly. Use the named style functions below.
function _geodesic_color() {
	################################################################################################
	#
	# Today's bash lesson regarding arrays, associative arrays, and the -v test.
	#
	# It is remarkably hard to safely test weather a variable has been declared as an associative array.
	#
	### Background on indexing arrays in bash
	#
	# In bash, the expression `var[subscript]` has, unfortunately, two very different meanings,
	# depending on whether `var` has been declared as an associative array or not. If `var` has
	# NOT been declared an associative arry, then `subscript` is treated as an arithmetic expression.
	# Within an expression, shell variables may be referenced by name without using the parameter
	# expansion syntax, meaning `subscript` evaluates to `$subscript`, and the value of the variable
	# `$subscript` is treated as an arithmetic expression (subject to recursive expansion), which is expected
	# to yield a number. On the other hand, if `var` has been declared as an associative array, then
	# `subscript` is treated as a string and is used to look up the value associated with that key,
	# with no further interpretation of the string.
	#
	# This means that if `ary` has not been declared as an associative array, the expression
	# `$ary[TERM]` causes $TERM to be evaluated as an arithmetic expression, which, through dumb luck,
	# fails if $TERM is "xterm-256color" because the subscript expression is expanded like this:
	#   $TERM -> xterm-256color            # the value of $TERM
	#   $xterm - 256color -> 0 - 256color  # $xterm is not set, so it is treated as 0
	#   ERROR converting "256color" to an integer: value too great for base
	#
	# If `TERM` had been set to `xterm-256` then the expression would have successfully evaluated to -256.
	#
	### Testing to see if a variable has been declared
	#
	# In bash, the normal way to test if a variable is set is to use the -v test, as in [[ -v varname ]].
	# (Unlike the -z test, -v distinguishes between unset variables and variables set to the empty string.)
	# However, with arrays, -v tests if the given index is set. If `ary` is an array, associative or not,
	# [[ -v ary ]] is treated as [[ -v ary[0] ]] and is only true of that specific index (zero) has been assigned
	# a value. So for our purposes, we cannot use -v to test if `_geodesic_tput_cache` has been declared
	# but not initialized unless we do something like ensure that `_geodesic_tput_cache[0]` is always set.
	# While it would be relatively easy to ensure that `_geodesic_tput_cache[0]` is always set, it would
	# leave a very mistaken impression of what the [[ -v _geodesic_tput_cache ]] test is actually doing
	# and why it works. Since this is open source code, we want to set a better example.
	#
	### Testing to see if a variable has been declared as an associative array
	#
	# Starting with Bash version 5, parameter operators are available, in the form of ${parameter@operator}.
	# The "a" operator expands the expression into a string consisting of flag values representing parameter’s attributes.
	# For an associative array, the "a" operator expands to "A". For a plain array, it expands to "a".
	# Note that other attributes are possible, too. For example, an exported non-associative array expands to "ax".
	# This gives us a better solution. We can test if _geodesic_tput_cache has been declared as an associative
	# array by using [[ ${_geodesic_tput_cache@a} == "A" ]]. By putting this test first, we can short-circuit
	# the evaluation of `${_geodesic_tput_cache[TERM]}` and avoid the arithmetic evaluation error.
	#

	if [[ ${_geodesic_tput_cache@a} != "A" ]] || [[ "${_geodesic_tput_cache[TERM]}" != "$TERM" ]]; then
		_geodesic_tput_cache_init
	fi

	local style=$1
	shift

	printf "%s%s%s" "${_geodesic_tput_cache["$style"]}" "$*" "${_geodesic_tput_cache["${style}-off"]}"
}

# Named style helpers
#
# For each color there is "color" and "bold-color", where "bold-color" is the bold version of the color.
#
# These come in 2 flavors.
# - The plain ones include a newline in the end and do not include delimiters around the non-printing text.
# - The ones ending with "-n" do not include a newline and do include delimiters around the non-printing text.
#
# Note that the newline is stripped if run via command substitution, so
#   echo "$(red "Hello") World"
# will not have a newline between "Hello" and "World".
# However, you should still use the "-n" variants if your string is or might become part of a PS1 prompt.
# Otherwise, bash will not correctly calculate the visible length of the prompt and editing command history will break.
#
# We intentionally do not define blue or magenta, as blue is problematic in dark mode
# and magenta is too much like red in dark mode, plus it is used as a substitute for yellow in light mode.
# We do not define white or black, either, as we should use the terminal's default for those.
# However, those colors are available via _geodesic_color() if needed, and "white" and "black" are
# swapped in dark mode, so they are more appropriately called "bg" and "fg" respectively.
# Also, "yellow" is not necessarily yellow, it varies with the terminal theme, and
# would be better named "caution" or "info".

function _geodesic_generate_color_functions() {
	local color colors
	colors=(red green yellow cyan)

	if [[ "$1" != "dummy" ]]; then
		for color in "${colors[@]}"; do
			eval "function ${color}() { _geodesic_color ${color} \"\$*\"; }"
			eval "bold-${color}() { _geodesic_color bold-${color} \"\$*\"; }"
			eval "function ${color}-n() { _geodesic_color ${color}-n \"\$*\"; }"
			eval "bold-${color}-n() { _geodesic_color bold-${color}-n \"\$*\"; }"
		done
	else
		for color in "${colors[@]}"; do
			eval "function ${color}() { printf -- '%s\n' \"\$*\"; }"
			eval "bold-${color}() { printf -- '%s\n' \"\$*\"; }"
			eval "function ${color}-n() { printf -- '%s\n' \"\$*\"; }"
			eval "bold-${color}-n() { printf -- '%s\n' \"\$*\"; }"
		done
	fi
}

function bold() {
	_geodesic_color bold "$*"
}

# Actually, resets all graphics settings to their defaults.
function reset_terminal_colors() {
	tput sgr0
}

_geodesic_tput_cache_init
