#!/bin/bash
# Install fzf shell completion when an interactive shell is enabled
# This is a fix for: `/etc/bash_completion.d/fzf.sh: line 34: bind: warning: line editing not enabled`
if [ -t 1 ] && ! [ -e '/etc/bash_completion.d/fzf.sh' ]; then
	ln -s /usr/share/bash-completion/completions/fzf /etc/bash_completion.d/fzf.sh
fi

# https://github.com/junegunn/fzf/wiki/Color-schemes
# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit

# A lot of terminals (including Apple's) do not support 24-bit color and the mapping from 24-bit to 8-bit is horrible.
# So most of the color schemes are limited to the 256 ANSI colors that nearly every terminal supports.
# Color schemes that only render properly with 24_bit color support are suffixed with _24

function _set_fzf_default_opts() {
	local gray1="232"
	local gray2="233"
	local gray3="234"
	local gray4="235"
	local gray5="240"
	local gray6="241"
	local gray8="244"
	local gray9="245"
	local grayE="254"
	local veryPaleYellow="229"
	local salmon="174"
	local burntOrange="136"
	local orange="166"
	local red="160"
	local teal="150"
	local magenta="125"
	local violet="61"
	local blue="33"
	local cyan="37"
	local green="2"
	local olive="3"
	local keep="-1" # Keep the exsiting terminal setting for this field


	case "$1" in
	solar_24)
		export FZF_DEFAULT_OPTS='--color=bg+:#073642,bg:#002b36,spinner:#719e07,hl:#586e75
			--color=fg:#839496,header:#586e75,info:#cb4b16,pointer:#719e07
			--color=marker:#719e07,fg+:#839496,prompt:#719e07,hl+:#719e07'
		;;
	solar_light)
		## Solarized Light color scheme for fzf
		export FZF_DEFAULT_OPTS="--border
			--color fg:$keep,bg:$keep,hl:$blue,fg+:$gray4,bg+:$grayE,hl+:$blue
			--color info:$burntOrange,prompt:$burntOrange,pointer:$gray3,marker:$gray3,spinner:$burntOrange"
		;;
	solar_dark)
		# Solarized Dark color scheme for fzf
		export FZF_DEFAULT_OPTS="--border
			--color fg:$keep,bg:$keep,hl:$blue,fg+:$grayE,bg+:$gray4,hl+:$blue
			--color info:$burntOrange,prompt:$burntOrange,pointer:$veryPaleYellow
			--color marker:$veryPaleYellow,spinner:$burntOrange"
		;;
	dark | light | 16 | bw)
		# Built-in basic color schemes
		export FZF_DEFAULT_OPTS="--color=$1"
		;;
	mild|*) # "mild" is redundant with "*", but I want this to have an explicit name in case the default changes later
		export FZF_DEFAULT_OPTS="--border
			--color fg:$keep,bg:$keep,hl:$burntOrange,fg+:$olive,bg+:$gray2,hl+:$veryPaleYellow
			--color info:$teal,prompt:$blue,spinner:$teal,pointer:$orange,marker:$salmon,header:$green"
		;;
	esac
}

if [[ -z $FZF_DEFAULT_OPTS ]]; then
	_set_fzf_default_opts "$FZF_COLORS"
fi
