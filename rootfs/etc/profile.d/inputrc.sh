# If we do not have one of our own, source inputrc from localhost.
[ ! -f ~/.inputrc ] && [ -f /localhost/.inputrc ] &&
	# Use new bindings for current shell.
	bind -f /localhost/.inputrc
