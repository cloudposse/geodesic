# If we do not have one of our own, source inputrc from localhost.
if [ ! -f ~/.inputrc ] && [ -f /localhost/.inputrc ]; then
	# Use new bindings for current shell.
	bind -f /localhost/.inputrc
fi
