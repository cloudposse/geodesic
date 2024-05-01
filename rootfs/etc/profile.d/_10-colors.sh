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

function update_terminal_mode() {
	local dark_mode=$(_is_term_dark_mode -b)
	if [[ ! -v _geodesic_tput_cache ]] || [[ "${_geodesic_tput_cache[dark_mode]}" != "$dark_mode" ]]; then
		_geodesic_tput_cache_init
	else
		local mode="light"
		if [[ $dark_mode == "true" ]]; then
			mode="dark"
		fi
		echo "Not updating terminal mode from $mode to $mode"
	fi
}

# We call `tput` several times for every prompt, and it can add up, so we cache the results.
function _geodesic_tput_cache_init() {
	declare -g -A _geodesic_tput_cache

	local color_off=$(tput op) # reset foreground and background colors to defaults
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
		[black]=$(tput setaf 0)
		[red]=$(tput setaf 1)
		[green]=$(tput setaf 2)
		[yellow]=$(tput setaf 3)
		[blue]=$(tput setaf 4)
		[magenta]=$(tput setaf 5)
		[cyan]=$(tput setaf 6)
		[white]=$(tput setaf 7)
	)

	if _is_term_dark_mode; then
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

	# Save the terminal type so we can invalidate the cache if it changes
	_geodesic_tput_cache[TERM]="$TERM"
	_geodesic_tput_cache[dark_mode]="$(_is_term_dark_mode -b)"
}

# Colorize text using ANSI escape codes.
# Usage: _geodesic_color style text...
# `style` is defined by the keys of the associative array _geodesic_tput_cache set up above.
# Not intended to be called directly. Use the named style functions below.
function _geodesic_color() {
	# The -v test is to see if the variable is set.
	# It is required because the associative array syntax does not work with unset variables.
	if [[ ! -v _geodesic_tput_cache ]] || [[ "${_geodesic_tput_cache[TERM]}" != "$TERM" ]]; then
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

function _generate_color_functions() {
	local color
	for color in red green yellow cyan; do
		eval "function ${color}() { _geodesic_color ${color} \"\$*\"; }"
		eval "bold-${color}() { _geodesic_color bold-${color} \"\$*\"; }"
		eval "function ${color}-n() { _geodesic_color ${color}-n \"\$*\"; }"
		eval "bold-${color}-n() { _geodesic_color bold-${color}-n \"\$*\"; }"
	done
}

_generate_color_functions
unset _generate_color_functions

function bold() {
	_geodesic_color bold "$*"
}

# Actually, resets all graphics settings to their defaults.
function reset_terminal_colors() {
	tput sgr0
}
