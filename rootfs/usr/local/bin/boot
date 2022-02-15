#!/bin/bash

[[ -t 1 ]] && (($# == 0)) && exec bash --login

if [[ $1 == "install" ]]; then
  function color() { echo "$(tput setaf 1)$*$(tput setaf 0)" >&2; }
  color "# EXIT THIS SHELL and on your host computer,"
  color "# run the following to install the script that runs "
elif [[ $1 = "wrapper" ]]; then
  function color() { echo "$*"; }
  color
  color "########################################################################################"
  color "# This is the end of the script that installs Geodesic. You should not be seeing this."
  color "# This should have been piped into bash. Use the following to install the script that runs"
elif [[ -n $DOCKER_IMAGE ]] && [[ -n $DOCKER_TAG ]]; then
  exec /usr/local/bin/init
else
  function color() { echo "$*"  >&2; }
  color "########################################################################################"
  color "# Attach a terminal (docker run --rm --it ...) if you want to run a shell."
  color "# Run the following to install the script that runs "
fi

source /etc/os-release || true # ignore exit code

color "# Geodesic with all its features (the recommended way to use Geodesic):"
color "#"
color "#   docker run --rm ${DOCKER_IMAGE:-cloudposse/geodesic}:${DOCKER_TAG:-latest${ID:+-$ID}} init | bash"
color "#"
color "# After that, you should be able to launch Geodesic just by typing"
color "#"
color "#   geodesic"
color "#"
color "########################################################################################"
echo
echo
