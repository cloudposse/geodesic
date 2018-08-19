if [ ! -d "${AWS_DATA_PATH}" ]; then
  echo "* Initializing ${AWS_DATA_PATH}"
  mkdir -p "${AWS_DATA_PATH}" 
fi

# `aws configure` does not respect ENVs
if [ ! -e "${HOME}/.aws" ]; then
  ln -s "${AWS_DATA_PATH}" "${HOME}/.aws"
fi


