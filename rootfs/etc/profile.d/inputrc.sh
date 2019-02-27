# if we do not have one, copy from localhost, and use bindings for this shell
[ -f ~/.inputrc ] || {
    cp /localhost/.inputrc ~/.inputrc &&
        bind -f ~/.inputrc ;
}
# subsequent shells will read ~/.inputrc at startup, unless INPUTRC is set.

