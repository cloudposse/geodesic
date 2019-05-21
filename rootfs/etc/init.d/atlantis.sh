#!/bin/bash

# Start the atlantis server
if [ "${ATLANTIS_ENABLED}" == "true" ]; then
	which atlantis >/dev/null
	if [ $? -ne 0 ]; then
		echo "Atlantis is not installed"
		exit 1
	fi

	echo "Starting atlantis server..."
	set -e

	# Unset settings which don't make sense when operating as a standalone server that should use IAM roles
	unset AWS_DEFAULT_PROFILE
	unset AWS_PROFILE
	unset AWS_MFA_PROFILE

	if [ -z "${CHAMBER_KMS_KEY_ALIAS}" ]; then
		echo "WARN: CHAMBER_KMS_KEY_ALIAS is not set"
	fi

	# Download plugins to /var/lib/cache to speed up applies
	export TF_PLUGIN_CACHE_DIR=${TF_PLUGIN_CACHE_DIR:-/var/lib/terraform}

	if [ -n "${TF_LOG}" ]; then
		echo "WARN: TF_LOG is set which may expose secrets"
	fi

	# Disable prompts for variables that haven't had their values specified
	export TF_INPUT=false

	# Disable color on all terraform commands
	export TF_CLI_DEFAULT_NO_COLOR=true

	# Auto approve apply
	export TF_CLI_APPLY_AUTO_APPROVE=true

	# Disable color terminals (direnv)
	export TERM=dumb

	export ATLANTIS_CHAMBER_SERVICE=${ATLANTIS_CHAMBER_SERVICE:-atlantis}

	# Export environment from chamber to shell
	source <(chamber exec ${ATLANTIS_CHAMBER_SERVICE} -- sh -c "export -p")

	if [ -n "${ATLANTIS_IAM_ROLE_ARN}" ]; then
		# Map the Atlantis IAM Role ARN to the env we use everywhere in our root modules
		export TF_VAR_aws_assume_role_arn=${ATLANTIS_IAM_ROLE_ARN}
	fi

	# Set some defaults if none provided
	export ATLANTIS_USER=${ATLANTIS_USER:-atlantis}
	export ATLANTIS_GROUP=${ATLANTIS_GROUP:-atlantis}
	export ATLANTIS_HOME=${ATLANTIS_HOME:-/conf/atlantis}

	# create atlantis user & group
	(getent group ${ATLANTIS_GROUP} || addgroup ${ATLANTIS_GROUP}) >/dev/null
	(getent passwd ${ATLANTIS_USER} || adduser -h ${ATLANTIS_HOME} -S -G ${ATLANTIS_GROUP} ${ATLANTIS_USER}) >/dev/null

	# Provision terraform cache directory
	install --directory ${TF_PLUGIN_CACHE_DIR} --owner ${ATLANTIS_USER} --group ${ATLANTIS_GROUP}

	# Allow atlantis to use /dev/shm
	if [ -d /dev/shm ]; then
		chown "${ATLANTIS_USER}:${ATLANTIS_GROUP}" /dev/shm
		chmod 700 /dev/shm
	fi

	# Add SSH key to agent, if one is configured so we can pull from private git repos
	if [ -n "${ATLANTIS_SSH_PRIVATE_KEY}" ]; then
		source <(gosu ${ATLANTIS_USER} ssh-agent -s)
		ssh-add - <<<${ATLANTIS_SSH_PRIVATE_KEY}
		# Sanitize environment
		unset ATLANTIS_SSH_PRIVATE_KEY
	fi

	if [ -n "${ATLANTIS_ALLOW_PRIVILEGED_PORTS}" ]; then
		setcap "cap_net_bind_service=+ep" $(which atlantis)
	fi

	# Do not export these as Terraform environment variables
	export TFENV_BLACKLIST="^(AWS_ACCESS_KEY_ID|AWS_SECRET_ACCESS_KEY|AWS_SECURITY_TOKEN|AWS_SESSION_TOKEN|ATLANTIS_.*|GITHUB_.*)$"

	# Configure git credentials for atlantis to allow access to GitHub private repos
	export GITHUB_USER=${ATLANTIS_GH_USER}
	export GITHUB_TOKEN=${ATLANTIS_GH_TOKEN}

	# Force `git` to use HTTPS instead of SSH. With HTTPS, `git` will use the `GITHUB_TOKEN` to authenticate with GitHub (with SSH it won't)
	# https://ricostacruz.com/til/github-always-ssh
	# https://git-scm.com/docs/git-config#Documentation/git-config.txt-urlltbasegtinsteadOf
	# https://gist.github.com/Kovrinic/ea5e7123ab5c97d451804ea222ecd78a

	# The URL "git@github.com:" is used by `git` (e.g. `git clone`)
	gosu ${ATLANTIS_USER} git config --global url."https://github.com/".insteadOf "git@github.com:"
	# The URL "ssh://git@github.com/" is used by Terraform (e.g. `terraform init --from-module=...`)
	# NOTE: we use `--add` to append the second URL to the config file
	gosu ${ATLANTIS_USER} git config --global url."https://github.com/".insteadOf "ssh://git@github.com/" --add

	# https://git-scm.com/book/en/v2/Git-Tools-Credential-Storage
	# see rootfs/usr/local/bin/git-credential-github
	gosu ${ATLANTIS_USER} git config --global credential.helper 'github'

	# Use a primitive init handler to catch signals and handle them properly
	# Use gosu to drop privileges
	# Use env to setup the shell environment for atlantis
	# Then lastly, start the atlantis server
	exec dumb-init gosu ${ATLANTIS_USER} env BASH_ENV=/etc/direnv/bash atlantis server
fi
