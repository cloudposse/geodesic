# Automatically export the current environment to `TF_VAR`
# Use a regex defined in the `TFENV_WHITELIST` and `TFENV_BLACKLIST` environment variables to include and exclude variables
source <(tfenv sh -c "export -p")
