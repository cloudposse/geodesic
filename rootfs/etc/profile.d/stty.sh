# By default Ctrl-S (a.k.a C-s or ^S) stops terminal output.
# However, in bash, it is mapped to forward-search (through command history),
# which is the standard emacs mapping. Unfortunately, it cannot do both, and by default, stop output wins.
# This can be confusing and is definitely annoying in that it prevents the use of forward search.
# Mapping a different key to stop terminal output is one possibility, but most of the control keys are already
# mapped to something somewhere, so instead we just turn off the flow control altogether.

[ -t 1 ] && stty -ixon
