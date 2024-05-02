#!/bin/bash
# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _07-term-mode.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the functions defined here. The number portion is to ensure proper ordering among
# the high-priority scripts.
#
# This file has no dependencies and should come first.

# This function determines if the terminal is in dark mode.

# For now, we use OSC sequences to query the terminal's foreground and background colors.
# See https://invisible-island.net/xterm/ctlseqs/ctlseqs.html#h3-Operating-System-Commands
# Adapted from https://bugzilla.gnome.org/show_bug.cgi?id=733423#c2
#
# At some point we may introduce other methods to determine the terminal's color scheme.

# Normally this function produces no output, but with -b, it outputs "true" or "false",
# with -bb it outputs "true", "false", or "unknown". (Otherwise, unknown assume light mode.)
# With -m it outputs "dark" or "light", with -mm it outputs "dark", "light", or "unknown".
# and always returns true. With -l it outputs integer luminance values for foreground
# and background colors. With -ll it outputs labels on the luminance values as well.
function _is_term_dark_mode() {
	local x fg_rgb bg_rgb fg_lum bg_lum

	# Extract the RGB values of the foreground and background colors via OSC 10 and 11.
	# Redirect output to `/dev/tty` in case we are in a subshell where output is a pipe,
	# because this output has to go directly to the terminal.
	stty -echo
	echo -ne '\e]10;?\a\e]11;?\a' >/dev/tty
	IFS=: read -t 0.1 -d $'\a' x fg_rgb
	IFS=: read -t 0.1 -d $'\a' x bg_rgb
	stty echo

	if [[ -z $fg_rgb ]] || [[ -z $bg_rgb ]]; then
		if [[ $GEODESIC_TRACE =~ "terminal" ]]; then
			echo $(tput setaf 1)* TRACE: "Terminal did not respond to OSC 10 and 11 queries.$(tput sgr0)" >&2
		fi
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
		echo "$(tput set bold)($tput setaf 1)Terminal reported unknown color format: ${x#*;}$(tput sgr0)" >&2
		return 1
	fi

	# Convert the RGB values to luminance by summing the values.
	fg_lum=$(_srgb_to_luminance "$fg_rgb")
	bg_lum=$(_srgb_to_luminance "$bg_rgb")
	if [[ "$*" =~ -l ]]; then
		if [[ "$*" =~ -ll ]]; then
			echo "Foreground luminance: $fg_lum, Background luminance: $bg_lum"
		else
			echo "$fg_lum $bg_lum"
		fi
	fi
	# If the background luminance is less than the foreground luminance, we are in dark mode.
	if ((bg_lum < fg_lum)); then
		if [[ "$*" =~ -m ]]; then
			echo "dark"
		elif [[ "$*" =~ -b ]]; then
			echo "true"
		fi
		return 0
	fi
	# Not in dark mode, must be in light mode.
	if [[ "$*" =~ -m ]]; then
		echo "light"

	elif [[ "$*" =~ -b ]]; then
		echo "false"
	else
		return 1
	fi
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
		if [[ $GEODESIC_TRACE =~ "terminal" ]]; then
			# Use tput and sgr0 here because this is early in the startup sequence and trace logging
			echo "$(tput setaf 1)* TRACE: ${FUNCNAME[0]} called with empty or no argument.$(tput sgr0)" >&2
		fi
		echo "0"
		return
	fi

	# Split the color string into red, green, and blue components
	IFS='/' read -r red green blue <<<"$color"

	# Normalize hexadecimal values to [0,1] and linearize them
	normalize_and_linearize() {
		local hex=${1^^} # Uppercase the hex value, because bc requires it
		local float=$(echo "ibase=16; $hex" | bc)
		local max=$(echo "ibase=16; 1$(printf '%0*d' ${#hex} 0)" | bc) # Accommodate the number of digits
		local normalized=$(echo "scale=10; $float / ($max - 1)" | bc)

		# Apply gamma correction
		if (($(echo "$normalized <= 0.04045" | bc))); then
			echo "scale=10; $normalized / 12.92" | bc
		else
			echo "scale=20; e(l(($normalized + 0.055) / 1.055) * 2.4)" | bc -l
		fi
	}

	# Linearize each color component
	local R=$(normalize_and_linearize $red)
	local G=$(normalize_and_linearize $green)
	local B=$(normalize_and_linearize $blue)

	# Calculate luminance
	local luminance=$(echo "scale=10; 0.2126 * $R + 0.7152 * $G + 0.0722 * $B" | bc)

	# Luminance is on a scale of 0 to 1, but we want to be able to
	# compare integers in bash, so we multiply by a big enough value
	# to get an integer and maintain precision.
	echo "scale=0; ($(echo "scale=10; $luminance * 1000000000" | bc) + 0.5) / 1" | bc
}
