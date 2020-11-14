# while locale en_US.UTF-8 is specifically tailored for US English,
# it is not supported by default by minimal POSIX distributions,
# and under Debian, ignores leading underscores while sorting,
# which causes these profile files to be executed in the wrong order.
# The general recommendation is to use locale C.UTF-8 instead.
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
export LANGUAGE=C.UTF-8
