export GEODESIC_SHELL=true

cloud init

if [ -z "${SSH_AUTH_SOCK}" ]; then
  eval $(ssh-agent)
fi

[ -f "${KOPS_STATE_PATH}/id_rsa" ] && cloud kops add-ssh-key
