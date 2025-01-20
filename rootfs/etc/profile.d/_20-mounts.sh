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

	# If the user has set the `MAP_FILE_OWNERSHIP` environment variable to "true",
	# we will have host mounts with host ownership under /.FS_HOST and
	# and have the same mounts with ownership translation under /.FS_CONT (CONT = container).
	# Otherwise, all host mounts will be mounted directly at their host paths.
	local map=""
	export GEODESIC_HOST_PATHS=()
	if [[ "$MAP_FILE_OWNERSHIP" == "true" ]]; then
		local src="/.FS_HOST"
		local dest="/.FS_CONT"
		if
			map="${dest}"
			[[ -d "${src}" ]]
		then
			mkdir -p "${dest}"
		else
			red "# ERROR: Supposed host mount directory ${src} does not exist. Fatal error."
			return 9
		fi
		GEODESIC_HOST_PATHS+=("${src}/" "${dest}/")
		if [[ -z $GEODESIC_HOST_UID ]] || [[ -z $GEODESIC_HOST_GID ]]; then
			red '# ERROR: `$MAP_FILE_OWNERSHIP` is set to "true" but `$GEODESIC_HOST_UID` and `$GEODESIC_HOST_GID` are not set.'
			red '# File ownership mapping will not be enabled.'
			findmnt -fn "${dest}" >/dev/null ||
				mount --rbind "${src}" "${dest}"
		else
			green "# File ownership mapping enabled."
			green "# Files created on host will have UID:GID ${GEODESIC_HOST_UID}:${GEODESIC_HOST_GID} on host."
			local bindfs_opts=(-o nonempty ${GEODESIC_BINDFS_OPTIONS} "--map=${GEODESIC_HOST_UID}/0:@${GEODESIC_HOST_GID}/@0")
			# use bindfs to map all the host mounts, under `/.FS_HOST` to a container mounts under `/.FS_CONT`.
			# Accessing the container mounts will show the files with the mapped UID:GID.
			# This single mounting is best because it correctly handles individual file mounts, not just directories.
			findmnt -fn "${dest}" >/dev/null ||
				bindfs "${bindfs_opts[@]}" "${src}" "${dest}" && GEODESIC_HOST_PATHS+=("${src}/" "${dest}/") ||
				red "# ERROR: Failed to bindfs ${src} to ${dest} for file ownership mapping."
		fi
	fi

	# All the map functions (bindfs and mount --rbind) require that the target already exists before
	# the mount is attempted. This function ensures that the source exists and is the correct type,
	# and, if so, creates the target if it does not exist.
	function _ensure_dest() {
		local src="$1"
		local dest="$2"
		local type

		# Skip if the target is the same inode as the source
		if [[ "${src}" -ef "${dest}" ]]; then
			type="same"
		# Skip if the source is a symlink, as this should never happen,
		# because we take no care to be sure the target of the symlink is also mounted.
		elif [[ -L "${src}" ]]; then
			red "# ERROR: Supposedly mounted '${src}' is a symlink. Skipping."
			type="symlink"
		# Make the target directory if the source is a directory
		elif [[ -d "${src}" ]]; then
			mkdir -p "${dest}"
			type="dir"
		# Make the target file if the source is a file,
		# which requires making the directory the target file will be in,
		# if it does not already exist.
		elif [[ -f "${src}" ]]; then
			if ! [[ -f "${dest}" ]]; then
				mkdir -p "$(dirname "${dest}")"
				touch "${dest}"
			fi
			type="file"
		else
			red "# ERROR: Supposedly mounted '${src}' is not a directory or file. Skipping."
			type="missing"
		fi
		echo "${type}"
	}

	# Map a directory or file from the host path to the container path
	function _map_host() {
		local src="$1"
		local dest="$2"
		local type="$(_ensure_dest "${src}" "${dest}")"

		[[ $type == "dir" ]] && GEODESIC_HOST_PATHS+=("${src}/" "${dest}/")

		if [[ "$type" == "dir" ]] || [[ "$type" = "file" ]]; then
			findmnt -fn "${dest}" >/dev/null ||
				mount --rbind "${src}" "${dest}" || red "# ERROR: Failed to mount ${src} to ${dest} for container path mapping."
		fi
	}

	# If file ownership mapping is enabled, map the ownership translated mounts
	# to the host files system paths. Otherwise do nothing.
	function _map_owner_mapped() {
		[[ -n "${map}" ]] || return 0
		local dest="$1"
		local src="${map}${dest}"

		local type="$(_ensure_dest "${src}" "${dest}")"
		if [[ "$type" == "dir" ]] || [[ "$type" = "file" ]]; then
			findmnt -fn "${dest}" >/dev/null ||
				mount --rbind "${src}" "${dest}" || red "# ERROR: Failed to mount ${src} to ${dest} for host path mapping."
		fi
	}

	# Host mounts are already mounted at the desired path, no need to alias them,
	# but we may need to handle file ownership mapping.
	IFS='|' read -ra paths <<<"${GEODESIC_HOST_MOUNTS}"
	for p in "${paths[@]}"; do
		_map_owner_mapped "$p"
		[[ -d "$p" ]] && GEODESIC_HOST_PATHS+=("${p}/")
	done

	# Map the workspace mount
	# If Geodesic was started without the wrapper (e.g. `docker run ... geodesic`), the workspace
	# will not be mounted. In that case, we will not map the workspace.
	if [[ -z "${WORKSPACE_MOUNT_HOST_DIR}" ]] || [[ "${WORKSPACE_MOUNT_HOST_DIR}" == "${WORKSPACE_MOUNT}" ]]; then
		WORKSPACE_MOUNT_HOST_DIR="${WORKSPACE_MOUNT}"
		yellow "# No host mapping found for Workspace."
	else
		_map_owner_mapped "${WORKSPACE_MOUNT_HOST_DIR}"
		_map_host "${WORKSPACE_MOUNT_HOST_DIR}" "${WORKSPACE_MOUNT}"
	fi

	# Map the user's home directory subdirectories and files from the host ($LOCAL_HOME) to the container ($HOME)
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
		_map_owner_mapped "${LOCAL_HOME}/$d"
	done

	if [[ "${LOCAL_HOME}" == "${HOME}" ]]; then
		yellow "# LOCAL_HOME is the same as HOME. No need to map directories."
		return 0
	fi

	# Map the LOCAL_HOME directory to the HOME directory
	for d in "${dirs[@]}"; do
		_map_host "${LOCAL_HOME}/$d" "${HOME}/$d"
	done
}

function _add_symlinks() {
	local links dest src
	IFS='|' read -ra links <<<"${GEODESIC_HOST_SYMLINK}"
	for l in "${links[@]}"; do
		[[ -z "$l" ]] && continue
		local src dest
		IFS='>' read -r dest src <<<"$l"
		if [[ -z $src ]] || [[ -z $dest ]]; then
			red "# ERROR: Invalid symlink definition: $l"
			continue
		fi
		mkdir -p "$(dirname "$dest")"
		if [[ -e $dest ]]; then
			red "# ERROR: Symlink destination already exists: '$dest'"
			continue
		fi
		ln -sT "$src" "$dest" && yellow symlinking "'$src' -> '$dest'" || red "# ERROR: Failed to create symlink: '$src' -> '$dest'"
	done
}

if [[ $SHLVL == 1 ]]; then
	_map_mounts
  _add_symlinks

	# Ensure we do not have paths that match everything
	paths=("${GEODESIC_HOST_PATHS[@]}")
	GEODESIC_HOST_PATHS=()
	for p in "${paths[@]}"; do
		# Eliminate paths that are just slashes, or completely empty, which would match everything
		if ! [[ $p =~ ^/*$ ]]; then
			GEODESIC_HOST_PATHS+=("$p")
		fi
	done
fi

unset -f _map_mounts _map_owner _map_host _ensure_dest paths _add_symlinks
