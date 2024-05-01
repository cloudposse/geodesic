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

function _is_term_dark_mode() {
	# Extract the RGB values of the foreground and background colors via OSC 10 and 11.
	# Redirect output to `/dev/tty` in case we are in a subshell where output is a pipe,
	# because this output has to go directly to the terminal.
	stty -echo
	echo -ne '\e]10;?\a\e]11;?\a' >/dev/tty
	IFS=: read -t 0.1 -d $'\a' x fg_rgb
	IFS=: read -t 0.1 -d $'\a' x bg_rgb
	stty echo

	if [[ -n $fg_rgb ]] && [[ -n $bg_rgb ]]; then
		# Convert the RGB values to luminance by summing the values.
		fg_lum=$((0x$(sed 's%/% + 0x%g' <<<"$fg_rgb")))
		bg_lum=$((0x$(sed 's%/% + 0x%g' <<<"$bg_rgb")))
		# If the background luminance is less than the foreground luminance, we are in dark mode.
		if ((bg_lum < fg_lum)); then
			return 0
		fi
	fi
	# If we cannot determine the color scheme, we assume light mode for historical reasons.
	return 1
}
