# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _01-launch-warning.sh. The leading underscore is needed to ensure this file executes before
# other files with alphabetical names. The number portion is to ensure proper ordering among
# the high-priority scripts.
#
# This file has no dependencies and does not strictly need to come first,
# but it is nice to have the warnings come before other output.

# In case this output is being piped into a shell, print a warning message

# Specifically, this guards against:
#   docker run -it cloudposse/geodesic:latest-debian  | bash

printf 'printf "\\nIf piping Geodesic output into a shell, do not attach a terminal (-t flag)\\n\\r" >&2; exit 8;'
# In case this output is not being piped into a shell, hide the warning message.
# Use backspaces, because carriage returns may be ignored or translated into newlines.
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '                                                                                                      '
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
printf '\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b\b'
