# Install fzf shell completion when an interactive shell is enabled
# This is a fix for: `/etc/bash_completion.d/fzf.sh: line 34: bind: warning: line editing not enabled`
if [ -t 1 ] && ! [ -e '/etc/bash_completion.d/fzf.sh' ]; then
	ln -s /usr/share/bash-completion/completions/fzf /etc/bash_completion.d/fzf.sh
fi
