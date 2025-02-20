#!/bin/bash
# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _07-term-mode.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the functions defined here. The number portion is to ensure proper ordering among
# the high-priority scripts.
#
# This file has no dependencies and should come first.

# These function determine if the terminal is in light or dark mode.

# We have 2 different kinds of auto-detection to consider:
#
#   1. The initial auto-detection of the terminal color mode at startup.
#      This is very important, because parts of the Geodesic colored prompt
#      (among other things) can become invisible if the terminal is dark and
#      Geodesic thinks it is light.
#
#   2. The auto-detection of terminal color mode changes during the session.
#      This is less important for 2 reasons:
#
#      a. There is no standard way for the terminal to notify the shell that the
#         color mode has changed. Some terminals support SIGWINCH, but most do not.
#         So the best we can do is poll the terminal periodically, which is not ideal,
#         especially since it can be slow and can fail, and when it fails it causes
#         garbage characters to appear on the terminal as input.
#
#      b. The terminal color mode is not likely to change during a session, and if it does,
#         the user can manually update the color mode with `update-terminal-theme`.
#
#
# So, the initial detection needs to be enabled by default, and if disabled, needs to set the mode.
#   - Disable it by setting GEODESIC_TERM_THEME=light or =dark.
#
# The detection of changes during the session should be disabled by default, and if enabled, should
# be able to be disabled again.
#
#    - Enable it by setting GEODESIC_TERM_THEME_AUTO=enabled.
#

# First, at startup, let's try an OSC query. If we get no response, we will assume light mode
# and disable further queries.

function _terminal_trace() {
	if [[ $GEODESIC_TRACE =~ "terminal" ]]; then
		# Use tput and sgr0 here because this may be early in the startup sequence and trace logging when color functions are not yet available.
		echo "$(tput setaf 1)* TERMINAL TRACE: $*$(tput sgr0)" >&2
	fi
}

function _verify_terminal_queries_are_supported() {
	local colors
	# It is possible that the terminal supports color, but `tput` does not know about it.
	# Since we rely on `tput` to modify the colors, if `tput` does not support the terminal, we have to treat it as monochome.
	colors=$(tput colors 2>/dev/null) || colors=0

	if ! { [[ -t 0 ]] && [[ "$colors" -ge 8 ]]; }; then
		# Do not use _terminal_trace here, because it uses color codes on terminals and we have just verified that is not supported here.
		[[ $GEODESIC_TRACE =~ "terminal" ]] && echo "* TERMINAL TRACE: Not a (color) terminal. Disabling color detection." >&2
		export GEODESIC_TERM_THEME_AUTO=unsupported
		return 1
	fi

	if ! /usr/local/bin/terminal-theme-detector >/dev/null 2>&1; then
		_terminal_trace "terminal-theme-detector could not determine terminal color."
		export GEODESIC_TERM_THEME_AUTO=unsupported
		return 1
	fi

	# The following test is only relevant when we are using _raw_query_term.
	#	if ! { [[ -w /dev/tty ]] && [[ -r /dev/tty ]]; }; then
	#		_terminal_trace "Terminal is not writable or readable. Skipping color detection."
	#		_terminal_trace "You may need to run 'chmod o+rw /dev/tty' to enable color detection."
	#		_terminal_trace "You can disable color detection with 'export GEODESIC_TERM_COLOR_AUTO=disabled'."
	#		return 1
	#	fi

	return 0
}

[[ "${GEODESIC_TERM_THEME}" == "light" ]] || [[ "${GEODESIC_TERM_THEME}" == "dark" ]] || _verify_terminal_queries_are_supported

# This is the worker function that gets the terminal foreground and background colors in RGB
# and converts them to luminance values. If unknown, it returns 0 0.
# If forced "light" or "dark", it returns 0 1000000000 or 1000000000 0, respectively.
_get_terminal_luminance() {
	local fg_rgb bg_rgb fg_lum bg_lum

	if [[ "${GEODESIC_TERM_THEME}" == "light" ]] || [[ ${GEODESIC_TERM_THEME_AUTO} == "unsupported" ]]; then
		if [[ "${GEODESIC_TERM_THEME}" == "light" ]]; then
			_terminal_trace "Terminal mode forced to \"light\" by GEODESIC_TERM_THEME"
		else
			_terminal_trace "Terminal mode color detection is unsupported for this terminal."
			_terminal_trace "Function stack is ${FUNCNAME[@]}."
		fi
		echo "0 1000000000"
		return
	fi
	if [[ "${GEODESIC_TERM_THEME}" == "dark" ]]; then
		_terminal_trace "Terminal mode forced to \"dark\" by GEODESIC_TERM_THEME"
		echo "1000000000 0"
		return
	fi
	if ! IFS=';' read -r -t 3 fg_rgb bg_rgb < <(terminal-theme-detector 2>/dev/null) || [[ -z $fg_rgb ]] || [[ -z $bg_rgb ]]; then
		_terminal_trace "Terminal did not respond to color queries."
		echo "0 0"
		return
	fi

	# Convert the RGB values to luminance using colormetric formula.
	_terminal_trace "Foreground color: $fg_rgb, Background color: $bg_rgb"
	fg_lum=$(_srgb_to_luminance "$fg_rgb")
	bg_lum=$(_srgb_to_luminance "$bg_rgb")
	echo "$fg_lum $bg_lum"
}

# Normally this function produces no output, but with -b, it outputs "true" or "false",
# with -bb it outputs "true", "false", or "unknown". (Otherwise, unknown assumes light mode.)
# With -m it outputs "dark" or "light", with -mm it outputs "dark", "light", or "unknown",
# and always returns true. With -l it outputs integer luminance values for foreground
# and background colors. With -ll it outputs labels on the luminance values as well.
function _is_term_dark_mode() {
	local lum=($(_get_terminal_luminance))
	local fg=${lum[0]} bg=${lum[1]}
	local theme response

	if [[ $fg -eq $bg ]]; then
		theme="unknown"
	elif [[ $fg -gt $bg ]]; then
		theme="dark"
	else
		theme="light"
	fi

	if [[ $theme == "light" ]]; then
		case "$1" in
		-b | -bb) response="false" ;;
		-m | -mm) response="light" ;;
		-l) response="$fg $bg" ;;
		-ll) response="Foreground luminance: $fg, Background luminance: $bg" ;;
		*) return 1 ;;
		esac
	elif [[ $theme == "dark" ]]; then
		case "$1" in
		-b | -bb) response="true" ;;
		-m | -mm) response="dark" ;;
		-l) response="$fg $bg" ;;
		-ll) response="Foreground luminance: $fg, Background luminance: $bg" ;;
		*) return 0 ;;
		esac
	else
		# Default to light for historical compatibility
		case "$1" in
		-b) response="false" ;;
		-bb) response="unknown" ;;
		-m) response="light" ;;
		-mm) response="unknown" ;;
		-l) response="0 1000000000" ;;
		-ll) response="Foreground luminance: 0, Background luminance: 1000000000" ;;
		*) return 1 ;;
		esac
	fi
	echo "$response"
}

# Converting RGB to luminance is a lot more complex than summing the values.
# To begin with, you need to know the color space, and if it is not a standard
# one, then you need a full color profile. To start with, we assume sRGB,
# and perhaps can add more color spaces later.
#
# Note: if we just take the simple sum of RGB values, we get in trouble with
# blue backgrounds and foregrounds, which can have very high hex values but still be dark.
#
# To complicate matters, WCAG originally published the wrong formula for
# converting sRGB to luminance.  The sRGB space has a linear region, and the switch
# from linear to exponential should be 0.04045, not 0.03928.
# See https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
#
# Unfortunately, many online calculators use the wrong formula, which you can test
# by checking the luminance for #0a570a571010, which should be .0032746029, not .003274534
# However, there is no difference for 8-bit colors and, as you can see, for 16 bit colors,
# the difference is negligible.
#
# You can use ImageMagick's `convert` command to convert an sRGB color to luminance:
#   convert xc:<color> -intensity Rec709Luminance  -format "%[fx:intensity]" info:
# For #0a570a571010, this will output 0.00327457, which is slightly off, likely
# due to internal rounding.
#
function _srgb_to_luminance() {
	local color="$1"
	local red green blue

	if [[ -z $color ]]; then
		_terminal_trace "${FUNCNAME[0]} called with empty or no argument."
		echo "0"
		return
	fi

	# Split the color string into red, green, and blue components
	IFS='/' read -r red green blue <<<"$color"

	# Normalize hexadecimal values to [0,1] and linearize them
	normalize_and_linearize() {
		local hex float max normalized R G B luminance
		hex=${1^^} # Uppercase the hex value, because bc requires it
		float=$(echo "ibase=16; $hex" | bc)
		max=$(echo "ibase=16; 1$(printf '%0*d' ${#hex} 0)" | bc) # Accommodate the number of digits
		normalized=$(echo "scale=10; $float / ($max - 1)" | bc)

		# Apply gamma correction
		if (($(echo "$normalized <= 0.04045" | bc))); then
			echo "scale=10; $normalized / 12.92" | bc
		else
			echo "scale=20; e(l(($normalized + 0.055) / 1.055) * 2.4)" | bc -l
		fi
	}

	# Linearize each color component
	R=$(normalize_and_linearize $red)
	G=$(normalize_and_linearize $green)
	B=$(normalize_and_linearize $blue)

	# Calculate luminance
	luminance=$(echo "scale=10; 0.2126 * $R + 0.7152 * $G + 0.0722 * $B" | bc)

	# Luminance is on a scale of 0 to 1, but we want to be able to
	# compare integers in bash, so we multiply by a big enough value
	# to get an integer and maintain precision.
	echo "scale=0; ($(echo "scale=10; $luminance * 1000000000" | bc) + 0.5) / 1" | bc
}

# _raw_query_term is a helper function that queries the terminal for the foreground and background colors.
# It uses OSC sequences to query the terminal's foreground and background colors.
# See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
# Adapted from https://bugzilla.gnome.org/show_bug.cgi?id=733423#c2
# However, many terminals do not support OSC, and there are quirks (e.g. with final delimiter character) among those that do.
# See https://github.com/bash/terminal-colorsaurus/blob/main/doc/terminal-survey.md
#
# So we no longer use this, but it is here as a reference. We use the terminal-colorsaurus library
# because it is more thorough and still being maintained.
function _raw_query_term_mode() {
	# Extract the RGB values of the foreground and background colors via OSC 10 and 11.
	# Redirect output to `/dev/tty` in case we are in a subshell where output is a pipe,
	# because this output has to go directly to the terminal.
	saved_state=$(stty -g)
	trap 'stty "$saved_state"' EXIT
	_terminal_trace 'Checking terminal color scheme...'
	# Timeout of 2 was not enough when waking for sleep and in a signal handler.
	# We moved to the prompt hook, but IDE terminals still can be slow, so we give a generous timeout,
	# now that is a rare event.
	timeout_duration="2"
	stty -echo
	# Query the terminal for the foreground color. Use printf to ensure the string is output as a single block,
	# without interference from other processes writing to the terminal.
	printf '\e]10;?\a' >/dev/tty
	IFS=: read -rs -t "$timeout_duration" -d $'\a' x fg_rgb </dev/tty
	exit_code=$?
	[[ $exit_code -gt 128 ]] || [[ -z $fg_rgb ]] && [[ ${GEODESIC_TERM_THEME_UPDATING} == "true" ]] && export GEODESIC_TERM_COLOR_AUTO=disabled
	[[ $exit_code -gt 128 ]] || exit_code=0
	if [[ $exit_code -eq 0 ]] && [[ -n $fg_rgb ]]; then
		# Query the terminal for the background color
		printf '\e]11;?\a' >/dev/tty
		IFS=: read -rs -t "$timeout_duration" -d $'\a' x bg_rgb </dev/tty
		exit_code=$?
		[[ $exit_code -gt 128 ]] || [[ -z $bg_rgb ]] && [[ ${GEODESIC_TERM_THEME_UPDATING} == "true" ]] && export GEODESIC_TERM_COLOR_AUTO=disabled
	fi
	stty "$saved_state"
	trap - EXIT

	if [[ ${GEODESIC_TERM_THEME_UPDATING} == "true" ]] && [[ ${GEODESIC_TERM_COLOR_AUTO} == "disabled" ]]; then
		printf "\n\n################# Begin Message from Geodesic ################\n\n" >&2
		printf "\tTerminal automatic light/dark mode detection failed from shell prompt hook. Disabling automatic detection.\n" >&2
		printf "\tYou can manually change modes with\n\n\tupdate-terminal-theme [dark|light]\n\n" >&2
		printf "\tYou can re-enable automatic detection with\n\n\tunset GEODESIC_TERM_COLOR_AUTO\n\n" >&2
		printf "################# End Message from Geodesic ##################\n\n" >&2
		echo "auto-detect-failed"
		return 9
	fi

	if [[ $exit_code -gt 128 ]] || [[ -z $fg_rgb ]] || [[ -z $bg_rgb ]]; then
		_terminal_trace "Terminal did not respond to OSC 10 and 11 queries."
		# If we cannot determine the color scheme, we assume light mode for historical reasons.
		if [[ "$*" =~ -b ]] || [[ "$*" =~ -m ]]; then
			if [[ "$*" =~ -bb ]] || [[ "$*" =~ -mm ]]; then
				echo "unknown"
			elif [[ "$*" =~ -m ]]; then
				echo "light"
			else
				echo "false"
			fi
			return 0 # when returning text, always return success
		fi
		return 1 # Assume light mode
	fi

	if [[ "${x#*;}" != "rgb" ]]; then
		# Always output this error, because we want to hear about
		# other color formats users want us to support.
		echo "$(tput set bold)$(tput setaf 1)Terminal reported unknown color format: ${x#*;}$(tput sgr0)" >&2
		return 1
	fi
}
