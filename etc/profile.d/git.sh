# Git defaults
if [ ! -f "${XDG_CONFIG_HOME}/git/config" ]; then
  mkdir -p "${XDG_CONFIG_HOME}/git";
  touch "${XDG_CONFIG_HOME}/git/config"
  git config --global user.email ops@cloudposse.com
  git config --global user.name geodesic
fi

# Initialize git 
if [ ! -d ${CLOUD_STATE_PATH}/.git ]; then
  git -C ${CLOUD_STATE_PATH} init
  git -C  ${CLOUD_STATE_PATH} add .
fi


