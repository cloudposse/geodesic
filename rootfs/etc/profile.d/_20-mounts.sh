# Files in the profile.d directory are executed by the lexicographical order of their file names.
# This file is named _20-mounts.sh. The leading underscore is needed to ensure this file executes before
# other files that depend on the file system mapping defined here.
# The number portion is to ensure proper ordering among the high-priority scripts.
# This file has only depends on colors.sh and should come before any scripts that
# attempt to access files on the host.

# We only need to run this once, so we check the shell level to avoid running it in subshells.
# Still, we can run multiple shells, so it has to be idempotent.
function _map_mounts() {
	if ! [[ -d "${HOME}" ]]; then
		red "# ERROR: HOME directory ${HOME} does not exist. Fatal error."
		return 9
	fi

	export GEODESIC_HOST_PATHS=()
	local bindfs_opts=(-o nonempty ${GEODESIC_BINDFS_OPTIONS})
	if [[ "$MAP_FILE_OWNERSHIP" == "true" ]]; then
		GEODESIC_HOST_PATHS+=("/.BINDFS/")
		if [[ -z $GEODESIC_HOST_UID ]] || [[ -z $GEODESIC_HOST_GID ]]; then
			red '# ERROR: `$MAP_FILE_OWNERSHIP` is set to "true" but `$GEODESIC_HOST_UID` and `$GEODESIC_HOST_GID` are not set.'
			red '# File ownership mapping will not be enabled.'
		else
			green "# File ownership mapping enabled."
			green "# Files created on host will have UID:GID ${GEODESIC_HOST_UID}:${GEODESIC_HOST_GID} on host."
			bindfs_opts+=("--map=${GEODESIC_HOST_UID}/0:@${GEODESIC_HOST_GID}/@0")
		fi
	fi

	function _ensure_dest() {
		local src="$1"
		local dest="$2"
		local type

		if [[ "${src}" -ef "${dest}" ]]; then
			type="same"
		elif [[ -L "${src}" ]]; then
			red "# ERROR: Supposedly mounted '${src}' is a symlink. Skipping."
			type="symlink"
		elif [[ -d "${src}" ]]; then
			mkdir -p "${dest}"
			type="dir"
		elif [[ -f "${src}" ]]; then
			if ! [[ -f "${dest}" ]]; then
				mkdir -p "$(dirname "${dest}")"
				touch "${dest}"
			fi
			type="file"
		else
			red "# ERROR: Supposedly mounted '${src}' does not exist. Skipping."
			type="missing"
		fi
		echo "${type}"
	}

	function _map_owner() {
		[[ "$MAP_FILE_OWNERSHIP" == "true" ]] || return 0
		local dest="$1"
		local src="/.BINDFS${dest}"

		local type="$(_ensure_dest "${src}" "${dest}")"
		if [[ "$type" == "dir" ]] || [[ "$type" = "file" ]]; then
			findmnt -fn "${dest}" >/dev/null ||
				bindfs "${bindfs_opts[@]}" "${src}" "${dest}"
		fi
	}

	function _map_host() {
		local src="$1"
		local dest="$2"
		local type="$(_ensure_dest "${src}" "${dest}")"

		[[ $type == "dir" ]] && GEODESIC_HOST_PATHS+=("${src}/" "${dest}/")

		if [[ "$type" == "dir" ]] || [[ "$type" = "file" ]]; then
			findmnt -fn "${dest}" >/dev/null ||
				mount --bind "${src}" "${dest}"
		fi
	}

	# Host mounts are already mounted at the desired path, no need to alias them
	IFS='|' read -ra paths <<<"${GEODESIC_HOST_MOUNTS}"
	for p in "${paths[@]}"; do
		_map_owner "$p"
		[[ -d "$p" ]] && GEODESIC_HOST_PATHS+=("${p}/")
	done

	# Map the workspace mount
	if [[ -z "${WORKSPACE_MOUNT_HOST_DIR}" ]] || [[ "${WORKSPACE_MOUNT_HOST_DIR}" == "${WORKSPACE_MOUNT}" ]]; then
		WORKSPACE_MOUNT_HOST_DIR="${WORKSPACE_MOUNT}"
		yellow "# No host mapping found for Workspace."
	else
		_map_owner "${WORKSPACE_MOUNT_HOST_DIR}"
		_map_host "${WORKSPACE_MOUNT_HOST_DIR}" "${WORKSPACE_MOUNT}"
	fi

	# Map the home directory subdirectories

	# although we call it "dirs", it can be files too
	local dirs
	IFS='|' read -ra dirs <<<"${GEODESIC_HOMEDIR_MOUNTS}"
	if ((${#dirs[@]} == 0)); then
		yellow "# No host user home directories to map to container user home."
		return 0
	fi

	if [[ -z "${LOCAL_HOME}" ]]; then
		red "# ERROR: LOCAL_HOME is not set. Cannot map host user's home to container user's home."
		return 0
	fi

	# Set up file ownership mapping for the LOCAL_HOME directory
	for d in "${dirs[@]}"; do
		_map_owner "${LOCAL_HOME}/$d"
	done

	if [[ "${LOCAL_HOME}" == "${HOME}" ]]; then
		yellow "# LOCAL_HOME is the same as HOME. No need to map directories to ."
		return 0
	fi

	# Map the LOCAL_HOME directory to the HOME directory
	for d in "${dirs[@]}"; do
		_map_host "${LOCAL_HOME}/$d" "${HOME}/$d"
	done
}

if [[ $SHLVL == 1 ]]; then
	_map_mounts
fi

unset -f _map_mounts _map_owner _map_host _ensure_dest
