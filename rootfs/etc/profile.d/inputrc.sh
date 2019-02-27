# If we can, and do not have one, copy inputrc from localhost.
[ -f ~/.inputrc ] && [ -f /localhost/.inputrc ] || {
    cp /localhost/.inputrc ~/.inputrc &&
        # Use new bindings for current shell.
        bind -f ~/.inputrc ;
}
# Subsequent shells automatically read ${INPUTRC-"~/.inputrc"} at startup.
