# Default directory mounts for the user's home directory
homedir_default_mounts=".aws,.config,.emacs.d,.geodesic,.kube,.ssh,.terraform.d"

function require_installed() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "Cannot find '$1' installed on this system. Please install and try again."
		exit 1
	fi
}

## Verify we have the foundations in place

if [ "${GEODESIC_SHELL}" == "true" ]; then
	echo "Cannot run while in a geodesic shell"
	exit 1
fi

require_installed tr
require_installed grep
require_installed docker

if ! docker ps >/dev/null 2>&1; then
	echo "Unable to communicate with docker daemon. Make sure your environment is properly configured and then try again."
	exit 1
fi

## Set up the default configuration

# We use `WORKSPACE` as a shorthand, but it is too generic to be used as an environment variable.
# So we cache and unset it here to see if it otherwise would have been used.
# The user can set it in their launch_options.sh if they want to use it, or they can use GEODESIC_WORKSPACE.
# If the only setting comes from the inherited environment, then we print a warning later.
exported_workspace="${WORKSPACE}"
unset WORKSPACE

### Geodesic Settings
export GEODESIC_PORT=${GEODESIC_PORT:-$((30000 + $$ % 30000))}

export GEODESIC_HOST_CWD=$(pwd -P 2>/dev/null || pwd)

readonly OS=$(uname -s)

export USER_ID=$(id -u)
export GROUP_ID=$(id -g)

export options=()
export targets=()

### Docker defaults

export DOCKER_DNS=${DNS:-${DOCKER_DNS}}
DOCKER_DETACH_KEYS="ctrl-@,ctrl-[,ctrl-@"

## Read in custom configuration here, so it can override defaults

export GEODESIC_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/geodesic"
if ! [ -d "$GEODESIC_CONFIG_HOME" ] && [ -d "$HOME/.geodesic" ]; then
	GEODESIC_CONFIG_HOME="$HOME/.geodesic"
fi

verbose_buffer=()
launch_options="$GEODESIC_CONFIG_HOME/defaults/launch-options.sh"
if [ -f "$launch_options" ]; then
	source "$launch_options" && verbose_buffer+=("Configuration loaded from $launch_options") || printf 'Error loading configuration from %s\n' "$launch_options" >&2
else
	verbose_buffer+=("Not found (OK): $launch_options")
fi

# Wait until here to parse $DOCKER_IMAGE, so that it can be overridden in $GEODESIC_CONFIG_HOME/launch-options.sh

if [ -n "${GEODESIC_NAME}" ]; then
	export DOCKER_NAME=$(basename "${GEODESIC_NAME:-}")
fi

if [ -n "${GEODESIC_TAG}" ]; then
	export DOCKER_TAG=${GEODESIC_TAG}
fi

if [ -n "${GEODESIC_IMAGE}" ]; then
	export DOCKER_IMAGE=${GEODESIC_IMAGE:-${DOCKER_IMAGE}}:${DOCKER_TAG}
else
	export DOCKER_IMAGE=${DOCKER_IMAGE}:${DOCKER_TAG}
fi

if [ -z "${DOCKER_IMAGE}" ]; then
	echo "Error: --image not specified (E.g. --image=cloudposse/foobar.example.com:1.0)"
	exit 1
fi

docker_stage="${DOCKER_IMAGE##*/}" # remove the registry and org
docker_stage="${docker_stage%%:*}" # remove the tag
docker_org="${DOCKER_IMAGE%/*}"    # remove the name and tag
# If the docker image is in the form of "docker.io/library/alpine:latest", then docker_org is "docker.io/library".
# Remove the "docker.io/" prefix if it exists.
docker_org="${docker_org#*/}"

for dir in "$docker_org" "$docker_stage" "$docker_org/$docker_stage"; do
	docker_image_launch_options="$GEODESIC_CONFIG_HOME/${dir}/launch-options.sh"
	if [ -f "$docker_image_launch_options" ]; then
		source "$docker_image_launch_options" && verbose_buffer+=("Configuration loaded from $docker_image_launch_options") || printf 'Error loading configuration from %s' "$docker_image_launch_options" >&2
	else
		verbose_buffer+=("Not found (OK): $docker_image_launch_options")
	fi
done

# GEODESIC_CONFIG_HOME="${GEODESIC_CONFIG_HOME#${HOME}/}"

function parse_args() {
	local arg
	while [[ $1 ]]; do
		arg="$1"
		shift
		case "$arg" in
		-h | --help)
			targets+=("help")
			;;
		-v | --verbose)
			export VERBOSE=true
			;;
		--solo)
			export ONE_SHELL=true
			;;
		--no-solo|--no-one-shell)
			export ONE_SHELL=false
			;;
		--trace)
			export GEODESIC_TRACE=custom
			;;
		--trace=*)
			export GEODESIC_TRACE="${1#*=}"
			;;
		--no-custom*)
			export GEODESIC_CUSTOMIZATION_DISABLED=true
			;;
		--no-motd*)
			export GEODESIC_MOTD_ENABLED=false
			;;
		--workspace=*)
			unset WORKSPACE_FOLDER_HOST_DIR
			;& # fall through
		--*)
			options+=("${arg}")
			;;
		--) # End of all options
			break
			;;
		-*)
			echo "Error: Unknown option: ${arg}" >&2
			exit 1
			;;
		*=*)
			declare -g "${arg}"
			;;
		*)
			targets+=("${arg}")
			;;
		esac
	done
}

function help() {
	echo "Usage: $0 [target] [options] [ARGS]"
	echo ""
	echo "  Targets:"
	echo "    <empty> | use              Enter into a shell, passing ARGS to the shell"
	echo "    help                       Show this help"
	echo "    stop [container-name]      Stop a running Geodesic container"
	echo ""
	echo "  Options:"
	echo "    --no-custom           Disable loading of custom configuration"
	echo "    --no-motd             Disable the MOTD"
	echo "    --solo                Launch a new container exclusively for this shell"
	echo "    --no-solo             Override the 'solo/ONE_SHELL' setting in your configuration"
	echo "    --trace               Enable tracing of shell customization within Geodesic"
	echo "    --trace=<options>     Enable tracing of specific parts of shell configuration"
	echo "    -v --verbose          Enable verbose output of launch configuration"
	echo ""
	echo "    trace options can be any of:"
	echo "      custom              Trace the loading of custom configuration in Geodesic"
	echo "      hist                Trace the determination of which shell history file to use"
	echo "      terminal            Trace the terminal color mode detection"
	echo "    You can specify multiple modes, separated by commas, e.g. --trace=custom,hist"
	echo ""
	echo "  Options that only take effect when starting a container:"
	echo "    --workspace           Set which host directory is used as the working directory in the container "
	echo ""
}

function options_to_env() {
	local kv
	local k
	local v

	for option in "${options[@]}"; do
		# Safely split on '='
		IFS='=' read -r -a kv <<<"$option"
		k=${kv[0]}                                  # Take first element as key
		k=${k#--}                                   # Strip leading --
		k=${k//-/_}                                 # Convert dashes to underscores
		k=$(echo "$k" | tr '[:lower:]' '[:upper:]') # Convert to uppercase (bash3 compat)
		# Treat remaining elements as value, restoring the '=' separator
		# This preserves multiple consecutive whitespace characters
		v="$(IFS='=' echo "${kv[*]:1}")"
		v="${v:-true}" # Set it to true for boolean flags

		export "$k"="$v"
	done
}

parse_args "$@"
options_to_env

[ "$VERBOSE" = "true" ] && [ -n "$verbose_buffer" ] && printf "%s\n" "${verbose_buffer[@]}"

function debug() {
	if [ "${VERBOSE}" == "true" ]; then
		echo "[DEBUG] $*"
	fi
}

function _running_shell_count() {
	local count=$(docker exec "${DOCKER_NAME}" pgrep -f "^/bin/(ba)?sh -l" 2>/dev/null | wc -l | tr -d " " || true)
	[ -n "${count}" ] || count=0
	echo "${count}"
}

function _on_shell_exit() {
	command -v "${ON_SHELL_EXIT:=geodesic_on_exit}" >/dev/null && "${ON_SHELL_EXIT}"
}

function _on_container_exit() {
	export GEODESIC_EXITING_CONTAINER_ID="${CONTAINER_ID:0:12}"
	export GEODESIC_EXITING_CONTAINER_NAME="${DOCKER_NAME}"
	_on_shell_exit
	[ -n "${ON_CONTAINER_EXIT}" ] && command -v "${ON_CONTAINER_EXIT}" >/dev/null && "${ON_CONTAINER_EXIT}"
}

function run_exit_hooks() {
	# This runs as soon as the terminal is detached. It may take moments for the shell to actually exit.
	# It can then take at least a second for the init process to quit.
	# There can then be a further delay before the container exits.
	# So we need to build in some delays to allow for these events to occur.

	if [[ ${ONE_SHELL} == "true" ]]; then
		# We can expect the Docker container to exit quickly, and do not need to report on it.
		_on_container_exit
		return 0
	fi

	# Initial count of running shells
	shells=$(_running_shell_count)
	if [ "$shells" -gt 1 ]; then
		# Even if our shell is included in the count, we know there are extra shells running.
		# Wait for our shell to quit and count again
		sleep 1
		shells=$(_running_shell_count)
		if [ "$shells" -eq 0 ]; then # coincidence, other shells quit too
			echo Other shells quit, too, and Docker container exited
			_on_container_exit
			return 0
		fi
	else # 1 or zero shells. The 1 might be ours, so we wait for it to quit.
		for i in {1..9}; do
			if [ $i -eq 9 ] || [ $(docker ps -q --filter "id=${CONTAINER_ID:0:12}" | wc -l | tr -d " ") -eq 0 ]; then
				break
			fi
			[ $i -lt 8 ] && sleep 1
		done
		if [ $i -eq 9 ]; then
			shells=$(_running_shell_count)
			if [ "$shells" -eq 0 ]; then
				printf 'All shells terminated, but docker container still running.\n' >&2
				printf 'Forcibly kill it with:\n\n    docker kill %s\n\n' "${DOCKER_NAME}" >&2
				_on_shell_exit
				return 6
			fi
		else
			echo Docker container exited
			_on_container_exit
			return 0
		fi
	fi

	# If we get here, container is still running and shells != 0
	echo Docker container still running
	[ "$shells" -eq 1 ] && echo -n "Quit 1 other shell " || echo -n "Quit $shells other shells "
	echo 'to terminate, or force quit with `docker kill '"${DOCKER_NAME}"'`'
	_on_shell_exit
}

function use() {
	[ "$1" = "use" ] && shift
	trap run_exit_hooks EXIT

	if [ "$ONE_SHELL" != "true" ]; then
		CONTAINER_ID=$(docker ps --filter name="^/${DOCKER_NAME}\$" --format '{{ .ID }}')
		if [ -n "$CONTAINER_ID" ]; then
			echo "# Starting shell in already running ${DOCKER_NAME} container ($CONTAINER_ID)"
			if [ $# -eq 0 ]; then
				set -- "/bin/bash" "-l" "$@"
			fi
			# We set unusual detach keys because (a) the default first char is ctrl-p, which is used for command history,
			# and (b) if you detach from the shell, there is no way to reattach to it, so we want to effectively disable detach.
			docker exec -it --detach-keys "ctrl-^,ctrl-[,ctrl-@" --env GEODESIC_HOST_CWD="${GEODESIC_HOST_CWD}" "${DOCKER_NAME}" $*
			return 0
		fi
	fi

	DOCKER_ARGS=()
	if [ -t 1 ]; then
		# Running in terminal
		DOCKER_ARGS+=(-it --rm --env LS_COLORS --env TERM --env TERM_COLOR --env TERM_PROGRAM --env GEODESIC_MOTD_ENABLED)
		if [ -n "$SSH_AUTH_SOCK" ]; then
			DOCKER_ARGS+=(--volume /run/host-services/ssh-auth.sock:/run/host-services/ssh-auth.sock
				-e SSH_AUTH_SOCK=/run/host-services/ssh-auth.sock)
		fi
		# Some settings from the host environment need to propagate into the container
		# Set them explicitly so they do not have to be exported in `launch-options.sh`
		for v in GEODESIC_CONFIG_HOME GEODESIC_MOTD_ENABLED GEODESIC_TERM_COLOR_AUTO; do
			# Test if variable is set in a way that works on bash 3.2, which is what macOS has.
			if [ -n "${!v+x}" ]; then
				DOCKER_ARGS+=(--env "$v=${!v}")
			fi
		done
	fi

	if [ "${WITH_DOCKER}" == "true" ]; then
		# Bind-mount docker socket into container
		# Should work on Linux and Mac.
		# Note that the mounted /var/run/docker.sock is not a file or
		# socket in the Mac host OS, it is in the dockerd VM.
		# https://docs.docker.com/docker-for-mac/osxfs/#namespaces
		echo "# Enabling docker support. Be sure you install a docker CLI binary${docker_install_prompt}."
		DOCKER_ARGS+=(--volume "/var/run/docker.sock:/var/run/docker.sock")
		# NOTE: bind mounting the docker CLI binary is no longer recommended and usually does not work.
		# Use a docker image with a docker CLI binary installed that is appropriate to the image's OS.
	fi

	if [[ ${GEODESIC_CUSTOMIZATION_DISABLED-false} == false ]]; then
		if [ -n "${GEODESIC_TRACE}" ]; then
			DOCKER_ARGS+=(--env GEODESIC_TRACE)
		fi

		if [ -n "${ENV_FILE}" ]; then
			DOCKER_ARGS+=(--env-file ${ENV_FILE})
		fi
	else
		echo "# Disabling user customizations: GEODESIC_CUSTOMIZATION_DISABLED is set and not 'false'"
		DOCKER_ARGS+=(--env GEODESIC_CUSTOMIZATION_DISABLED)
	fi

	if [ -n "${DOCKER_DNS}" ]; then
		DOCKER_ARGS+=("--dns=${DOCKER_DNS}")
	fi

	# Mount the user's home directory into the container
	# but allow them to specify some directory other than their actual home directory
	if [ -n "${LOCAL_HOME}" ]; then
		local_home=${LOCAL_HOME}
	else
		local_home=${HOME}
	fi

	## Directory/file mounting plan:
	##
	##   Host directory/file -> Container directory/file
	##   * Normal case, Docker handles mapping of file ownership between host and container.
	##     Mount the host directory into the container at the same path.
	##   * If Docker is not properly mapping file ownership, we set up explicit mapping using `bindfs`.
	##     * This is enabled by the user setting MAP_FILE_OWNERSHIP=true.
	##     * In this case, we mount the host directory into the container under /.FS_HOST, but again
	##       using the same host path. Example: /home/user -> /.FS_HOST/home/user
	##     * We then (inside the container as part of login) bind mount /.FS_HOST into /.FS_CONT
	##       using `bindfs` to do explicit file ownership mapping. Example: /.FS_HOST/home/user -> /.FS_CONT/home/user
	##     * This allows the user to access the files with the correct ownership. More importantly,
	##       it correctly manages individual file mounts, not just directories.
	##     * Still inside the container, we then mount the mounts under /.FS_CONT into the
	##       host path, but now with the correct ownership. Example: /.FS_CONT/home/user -> /home/user
	##
	##    Container host path to container path:
	##    Most of the mounted directories need to appear at a different path in the container than on
	##    the host. After the above mappings setting up the host paths, we then mount the host paths
	##    into the container at the correct container path.
	mount_dir=""
	if [ -n "${GEODESIC_HOST_BINDFS_ENABLED+x}" ]; then
		echo "# WARNING: GEODESIC_HOST_BINDFS_ENABLED is deprecated. Use MAP_FILE_OWNERSHIP instead."
		export MAP_FILE_OWNERSHIP="${GEODESIC_HOST_BINDFS_ENABLED}"
	fi
	if [ "${MAP_FILE_OWNERSHIP}" = "true" ]; then
		if [ "${USER_ID}" = 0 ]; then
			echo "# WARNING: Host user is root. This is DANGEROUS."
			echo "  * Geodesic should not be launched by the host root user."
			echo "  * Use \"rootless\" mode instead. See https://docs.docker.com/engine/security/rootless/"
			echo "# Not enabling BindFS host filesystem mapping because host user is root, same as default container user."
		else
			echo "# Enabling explicit mapping of file owner and group ID between container and host."
			mount_dir="/.FS_HOST"
			DOCKER_ARGS+=(
				--env GEODESIC_HOST_UID="${USER_ID}"
				--env GEODESIC_HOST_GID="${GROUP_ID}"
				--env GEODESIC_BINDFS_OPTIONS
				--env MAP_FILE_OWNERSHIP=true
			)
		fi
	fi

	# Although we call it "dirs", it can be files too
	export GEODESIC_HOMEDIR_MOUNTS=""
	DOCKER_ARGS+=(--env GEODESIC_HOMEDIR_MOUNTS --env LOCAL_HOME="${local_home}")
	[ -z "${HOMEDIR_MOUNTS+x}" ] && HOMEDIR_MOUNTS=("${homedir_default_mounts[@]}")
	IFS=, read -ra HOMEDIR_MOUNTS <<<"${HOMEDIR_MOUNTS}"
	IFS=, read -ra HOMEDIR_ADDITIONAL_MOUNTS <<<"${HOMEDIR_ADDITIONAL_MOUNTS}"
	for dir in "${HOMEDIR_MOUNTS[@]}" "${HOMEDIR_ADDITIONAL_MOUNTS[@]}"; do
		if [ -d "${local_home}/${dir}" ] || [ -f "${local_home}/${dir}" ]; then
			DOCKER_ARGS+=(--volume="${local_home}/${dir}:${mount_dir}${local_home}/${dir}")
			GEODESIC_HOMEDIR_MOUNTS+="${dir}|"
			debug "Mounting '${local_home}/${dir}' into container'"
		else
			debug "Not mounting '${local_home}/${dir}' into container because it is not a directory or file"
		fi
	done

	# WORKSPACE_MOUNT is the directory in the container that is to be the mount point for the host filesystem
	WORKSPACE_MOUNT="${WORKSPACE_MOUNT:-/workspace}"
	# WORKSPACE_HOST_DIR is the directory on the host that is to be the working directory
	if [ -n "$WORKSPACE" ] && [ -n "$WORKSPACE_FOLDER_HOST_DIR" ] && [ "$WORKSPACE" != "$WORKSPACE_FOLDER_HOST_DIR" ]; then
		echo "# WORKSPACE is set to '${WORKSPACE}'."
		echo "# WORKSPACE_FOLDER_HOST_DIR is set to '${WORKSPACE_FOLDER_HOST_DIR}'."
		echo "# Ignoring WORKSPACE and using WORKSPACE_FOLDER_HOST_DIR as the workspace folder/work directory."
		unset exported_workspace
	fi
	WORKSPACE_FOLDER_HOST_DIR="${WORKSPACE_FOLDER_HOST_DIR:-${WORKSPACE:-${GEODESIC_HOST_CWD}}}"
	if [ -n "$exported_workspace" ] && [ "$exported_workspace" != "$WORKSPACE" ]; then
		echo "# Ignoring exported WORKSPACE setting of '$exported_workspace'." >&2
		echo "# Export GEODESIC_WORKSPACE or set WORKSPACE in 'launch-config.sh' or via '--workspace' if you want Geodesic to use it." >&2
		echo "# Using '$WORKSPACE' as the workspace folder/work directory." >&2
	fi
	git_root=$(
		cd "${WORKSPACE_FOLDER_HOST_DIR}" || {
			echo Cannot change to workspace folder directory "'${WORKSPACE_FOLDER_HOST_DIR}'", quitting >&2
			echo "WORKSPACE or WORKSPACE_FOLDER_HOST_DIR, if set, must be set to an accessible directory" >&2
			exit 33
		} &&
			git rev-parse --show-toplevel 2>/dev/null
	)
	[ "$?" -eq 33 ] && exit 33 # do not abort if git rev-parse fails
	# Resolve symbolic links to get the actual path
	local configured_wfhd
	configured_wfhd="$WORKSPACE_FOLDER_HOST_DIR"
	WORKSPACE_FOLDER_HOST_DIR="$(cd "${WORKSPACE_FOLDER_HOST_DIR}" && pwd -P || echo "${WORKSPACE_FOLDER_HOST_DIR}")"
	if [ -z "${git_root}" ] || [ "$git_root" = "${WORKSPACE_FOLDER_HOST_DIR}" ]; then
		# WORKSPACE_HOST_PATH is the directory on the host that is to be mounted into the container
		WORKSPACE_MOUNT_HOST_DIR="${WORKSPACE_FOLDER_HOST_DIR}"
		WORKSPACE_FOLDER="${WORKSPACE_FOLDER:-${WORKSPACE_MOUNT}}"
	else
		# If we are in a git repo, mount the git root into the container at /workspace
		WORKSPACE_MOUNT_HOST_DIR="${git_root}"
		WORKSPACE_FOLDER="${WORKSPACE_FOLDER:-${WORKSPACE_MOUNT}/${WORKSPACE_FOLDER_HOST_DIR#${git_root}/}}"
	fi
	if [ "$configured_wfhd" != "$WORKSPACE_FOLDER_HOST_DIR" ]; then
		echo "# Resolved ${configured_wfhd} to '${WORKSPACE_FOLDER_HOST_DIR}'"
		export GEODESIC_HOST_SYMLINK+="${configured_wfhd}>${WORKSPACE_FOLDER_HOST_DIR}|"
	fi

	echo "# Mounting '${WORKSPACE_MOUNT_HOST_DIR}' into container at '${WORKSPACE_MOUNT}'"
	echo "# Setting container working directory to '${WORKSPACE_FOLDER}'"

	DOCKER_ARGS+=(
		--volume="${WORKSPACE_MOUNT_HOST_DIR}:${mount_dir}${WORKSPACE_MOUNT_HOST_DIR}"
		--env WORKSPACE_MOUNT_HOST_DIR="${WORKSPACE_MOUNT_HOST_DIR}"
		--env WORKSPACE_MOUNT="${WORKSPACE_MOUNT}"
		--env WORKSPACE_FOLDER="${WORKSPACE_FOLDER}"
	)
	[ -n "${GEODESIC_HOST_SYMLINK}" ] && DOCKER_ARGS+=(--env GEODESIC_HOST_SYMLINK)

	# Mount the host mounts wherever the users asks for them to be mounted.
	# However, if file ownership mapping is enabled,
	# we still need to mount them under /.FS_HOST first.
	# To enable final mapping, Geodesic needs to know what is mounted from the host,
	# so we provide that information in GEODESIC_HOST_MOUNTS.
	export GEODESIC_HOST_MOUNTS=""
	IFS=, read -ra HOST_MOUNTS <<<"${HOST_MOUNTS}"
	for dir in "${HOST_MOUNTS[@]}"; do
		d="${dir%%:*}"
		if [ -d "${d}" ]; then
			if [ "${dir}" != "${d}" ]; then
				DOCKER_ARGS+=(--volume="${d}:${mount_dir}${dir#*:}")
				debug "Mounting ${d} into container at ${dir#*:}"
				GEODESIC_HOST_MOUNTS+="${dir#*:}|"
			else
				DOCKER_ARGS+=(--volume="${d}:${mount_dir}${d}")
				debug "Mounting ${d} into container at ${d}"
				GEODESIC_HOST_MOUNTS+="${d}|"
			fi
		fi
	done

	DOCKER_ARGS+=(--env GEODESIC_HOST_MOUNTS)

	#echo "Computed DOCKER_ARGS:"
	#printf "   %s\n" "${DOCKER_ARGS[@]}"

	DOCKER_ARGS+=(
		--privileged
		--publish ${GEODESIC_PORT}:${GEODESIC_PORT}
		--rm
		--env GEODESIC_PORT=${GEODESIC_PORT}
		--env DOCKER_IMAGE="${DOCKER_IMAGE%:*}"
		--env DOCKER_NAME="${DOCKER_NAME}"
		--env DOCKER_TAG="${DOCKER_TAG}"
		--env GEODESIC_HOST_CWD="${GEODESIC_HOST_CWD}"
	)

	if [ "$ONE_SHELL" = "true" ]; then
		DOCKER_NAME="${DOCKER_NAME}-$(date +%d%H%M%S)"
		echo "# Starting single shell ${DOCKER_NAME} session from ${DOCKER_IMAGE}"
		echo "# Exposing port ${GEODESIC_PORT}"
		[ -z "${GEODESIC_DOCKER_EXTRA_ARGS}" ] || echo "# Launching with extra Docker args: ${GEODESIC_DOCKER_EXTRA_ARGS}"
		docker run --name "${DOCKER_NAME}" "${DOCKER_ARGS[@]}" ${GEODESIC_DOCKER_EXTRA_ARGS} ${DOCKER_IMAGE} -l $*
	else
		echo "# Running new ${DOCKER_NAME} container from ${DOCKER_IMAGE}"
		echo "# Exposing port ${GEODESIC_PORT}"
		[ -z "${GEODESIC_DOCKER_EXTRA_ARGS}" ] || echo "# Launching with extra Docker args: ${GEODESIC_DOCKER_EXTRA_ARGS}"
		# docker run "${DOCKER_ARGS[@]}" ${GEODESIC_DOCKER_EXTRA_ARGS} ${DOCKER_IMAGE} -l $*
		CONTAINER_ID=$(docker run --detach --init --name "${DOCKER_NAME}" "${DOCKER_ARGS[@]}" ${GEODESIC_DOCKER_EXTRA_ARGS} ${DOCKER_IMAGE} /usr/local/sbin/shell-monitor)
		echo "# Started session ${CONTAINER_ID:0:12}. Starting shell via \`docker exec\`..."
		docker exec -it --detach-keys "ctrl-^,ctrl-[,ctrl-@" --env GEODESIC_HOST_CWD="${GEODESIC_HOST_CWD}" "${DOCKER_NAME}" /bin/bash -l $*
	fi
	true
}

_polite_stop() {
	name="$1"
	[ -n "$name" ] || return 1
	if [ $(docker ps -q --filter "name=${name}" | wc -l | tr -d " ") -eq 0 ]; then
		echo "# No running containers found for ${name}"
		return
	fi

	printf "# Signalling '%s' to stop..." "${name}"
	docker kill -s TERM "${name}" >/dev/null
	for i in {1..9}; do
		if [ $i -eq 9 ] || [ $(docker ps -q --filter "name=${name}" | wc -l | tr -d " ") -eq 0 ]; then
			printf " '%s' stopped gracefully.\n\n" "${name}"
			return 0
		fi
		[ $i -lt 8 ] && sleep 1
	done

	printf " '%s' did not stop gracefully. Killing it.\n\n" "${name}"
	docker kill -s TERM "${name}" >/dev/null
	return 138
}

function stop() {
	exec 1>&2
	name=${targets[1]}
	if [ -n "$name" ]; then
		_polite_stop ${name}
		return $?
	fi
	RUNNING_NAMES=($(docker ps --filter name="^/${DOCKER_NAME}(-\d{8})?\$" --format '{{ .Names }}'))
	if [ -z "$RUNNING_NAMES" ]; then
		echo "# No running containers found for ${DOCKER_NAME}"
		return
	fi
	if [ ${#RUNNING_NAMES[@]} -eq 1 ]; then
		echo "# Stopping ${RUNNING_NAMES[@]}..."
		_polite_stop "${RUNNING_NAMES[@]}"
		return $?
	fi
	if [ ${#RUNNING_NAMES[@]} -gt 1 ]; then
		echo "# Multiple containers found for ${DOCKER_NAME}:"
		for id in "${RUNNING_NAMES[@]}"; do
			echo "#   ${id}"
		done
		echo "# Please specify a unique container name."
		echo "#    $0 stop <container_name>"
		return 1
	fi
}

if [ "${targets[0]}" = "stop" ]; then
	stop
elif [ -z "${targets[0]}" ] || [ "${targets[0]}" = "use" ]; then
	use "${targets[@]}"
else
	help
fi
