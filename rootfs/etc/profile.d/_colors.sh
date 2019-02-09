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

export FZF_DEFAULT_OPTS='
  --color=bg+:#073642,bg:#002b36,spinner:#719e07,hl:#586e75
  --color=fg:#839496,header:#586e75,info:#cb4b16,pointer:#719e07
  --color=marker:#719e07,fg+:#839496,prompt:#719e07,hl+:#719e07
'
