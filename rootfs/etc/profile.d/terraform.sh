PROMPT_HOOKS+=("terraform_prompt")
function terraform_prompt() {
  shopt -s nullglob
  TF_FILES=(*.tf)
  if [ ! -z "${TF_FILES}" ]; then
    if [ ! -d ".terraform" ]; then
      echo -e "-> Run '$(green init-terraform)' to use this project"
    fi
  fi
}

# Install autocompletion rules
if which terraform >/dev/null 2>&1; then
  complete -C /usr/local/bin/terraform terraform
fi
