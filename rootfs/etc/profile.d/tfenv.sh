# Automatically export the current environment to `TF_VAR`
# Use a regex defined in the `TFENV_WHITELIST` and `TFENV_BLACKLIST` environment variables to include and exclude variables
#
[[ ${LOAD_GLOBAL_TFENV:-false} == "true" ]] &&
	echo $(red Global use of) tfenv $(red is not recommended) &&
	echo $(red use the) '"use tfenv"' $(red function of) '"direnv"' $(red to automatically execute it in certain directories) &&
	source <(tfenv)
