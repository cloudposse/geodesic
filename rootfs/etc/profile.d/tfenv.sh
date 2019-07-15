# Automatically export the current environment to `TF_VAR`
# Use a regex defined in the `TFENV_WHITELIST` and `TFENV_BLACKLIST` environment variables to include and exclude variables
#

# Prevent tfenv from exporting sensitive environment variables
[[ -z "$TFENV_BLACKLIST" ]] && export TFENV_BLACKLIST="^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SECURITY_TOKEN|AWS_SESSION_TOKEN|ATLANTIS_.*|GITHUB_.*)$"

if [[ ${TFENV_LOAD_GLOBALLY:-false} == "true" ]]; then
	echo $(red Global use of) tfenv $(red is not recommended) &&
		echo $(red use the) '"use tfenv"' $(red function of) '"direnv"' $(red to automatically execute it in certain directories) &&
		source <(tfenv)
fi
