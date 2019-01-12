#!/bin/bash

# Start the atlantis server
if [ "${ATLANTIS_ENABLED}" == "true" ]; then
	which -s atlantis
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

	# Export environment from chamber to shell
	eval $(chamber exec ${ATLANTIS_CHAMBER_SERVICE} -- sh -c "export -p")

	# Export current environment to terraform style environment variables
	eval $(tfenv sh -c "export -p")

	# Set some defaults if none provided
	export ATLANTIS_USER=${ATLANTIS_USER:-atlantis}
	export ATLANTIS_GROUP=${ATLANTIS_GROUP:-atlantis}
	export ATLANTIS_CHAMBER_SERVICE=${ATLANTIS_CHAMBER_SERVICE:-atlantis}
	export ATLANTIS_HOME=${ATLANTIS_HOME:-/conf/atlantis}

	# create atlantis user & group
	(getent group ${ATLANTIS_GROUP} || addgroup ${ATLANTIS_GROUP}) >/dev/null
	(getent passwd ${ATLANTIS_USER} || adduser -h ${ATLANTIS_HOME} -S -G ${ATLANTIS_GROUP} ${ATLANTIS_USER}) >/dev/null

	# Allow atlantis to use /dev/shm
	if [ -d /dev/shm ]; then
		chown "${ATLANTIS_USER}:${ATLANTIS_GROUP}" /dev/shm
		chmod 700 /dev/shm
	fi

	# Add SSH key to agent, if one is configured so we can pull from private git repos
	if [ -n "${ATLANTIS_SSH_KEY}" ]; then
		eval $(ssh-agent -s)
		ssh-add - <<<${ATLANTIS_SSH_KEY}
		# Sanitize environment
		unset ATLANTIS_SSH_KEY
	fi

	if [ -n "${ATLANTIS_ALLOW_PRIVILEGED_PORTS}" ]; then
		setcap "cap_net_bind_service=+ep" $(which atlantis)
	fi
	exec dumb-init gosu ${ATLANTIS_USER} atlantis server
fi
