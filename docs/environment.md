---
title: environment(5) | Geodesic
author:
- Nuru
date: January 2025
---

Geodesic makes extensive use of environment variables for a variety of purposes.
This document is a reference of what variables are in use and what their purpose is.
It may be incomplete. Please update it as missing variables are found.

Geodesic version 4 additions and changes:

- `GEODESIC_LOCALHOST` prefixed variables have been removed.
- `HOMEDIR_MOUNTS` and `HOMEDIR_ADDITIONAL_MOUNTS` are input lists of directories relative to the home directory on the host
  to mount into the container under the container user's home directory.
- `GEODESIC_HOMEDIR_MOUNTS` is set inside the shell to be the union of `HOMEDIR_MOUNTS` and `HOMEDIR_ADDITIONAL_MOUNTS`.
- `HOST_MOUNTS` is a list of mounts from the host to the container. It has the format
  `host_path[:container_path]`. If the container_path is not specified, it is assumed to be the same as the host_path.
  This list excludes the home directory, which is handled separately.
- `GEODESIC_HOST_PATHS` is set inside the shell to an array of absolute file system paths that are mounted from the host.
- `WORKSPACE_FOLDER_HOST_DIR` is the base directory of the project on the host. Analogous to the target of Dev Container's
  `workspaceFolder`. **Defaults to the working directory from where you launched Geodesic**.
  Typically, this is the root of the Git repository holding your source code, but may be a subdirectory if the Git repository is
  a monorepo containing multiple projects. It must be an absolute path either equal to or a subdirectory of `WORKSPACE_MOUNT_HOST_DIR`.
  - Setting `WORKSPACE_FOLDER_HOST_DIR` in your Docker-image-specific `launch-options.sh` will allow you to launch your project's
    Geodesic app from any working directory and have the correct configuration inside Geodesic.
- `WORKSPACE_FOLDER` is the base directory of the project inside the container. Analogous to the target of Dev Container's
  `workspaceFolder`. Typically, this is the same as `WORKSPACE_MOUNT`, but may be a subdirectory if, for example, the Git repository is
  a "monorepo" containing multiple projects. It must be an absolute path either equal to or a subdirectory of `WORKSPACE_MOUNT`.
- `WORKSPACE_MOUNT_HOST_DIR` is the host directory where the project will be mounted. Analogous to the source of Dev Container's
  `workspaceMount`. Typically, this is a Git repository root. If `WORKSPACE_FOLDER_HOST_DIR` is in a subdirectory of the Git repository,
  `WORKSPACE_MOUNT_HOST_DIR` defaults to the repository root. Otherwise, it defaults to `WORKSPACE_FOLDER_HOST_DIR`.
- `WORKSPACE_MOUNT` is the container path where `WORKSPACE_MOUNT_HOST_DIR` will be mounted. Analogous to the target of Dev Container's
  `workspaceMount`. Defaults to `/workspace`, which is the default for a Dev Container, but you may want to set it to
  something like your project name or git repository name for visibility in the container.
- `GEODESIC_TERM_THEME` is normally unset. Geodesic will attempt to detect the terminal light/dark mode and default to light. Set this to "light" or "dark" to disable the automatic detection at startup and force the theme.
- `GEODESIC_TERM_THEME_AUTO` is normally unset. Set it to "true" to enable attempts to automatically detect _changes_ in terminal light/dark theme. Use `set-terminal-theme` to manually switch between light and dark themes.
- `GEODESIC_MOTD_ENABLED` can be set to "false" to disable printing the message of the day at shell startup.
- `MAP_FILE_OWNERSHIP` replaces `GEODESIC_HOST_BINDFS_ENABLED`. If set to true, Geodesic will use `bindfs` to map file ownership
  between the host and container. This not normally needed, as it should be handled automatically by Docker.

Starting with Geodesic version 4.4.0:

- `GEODESIC_DOCKER_EXTRA_ARGS` is deprecated. Geodesic distinguishes between options for launching a container
  and options for exec’ing into a running one. Use `GEODESIC_DOCKER_EXTRA_LAUNCH_ARGS` for container launch and
  `GEODESIC_DOCKER_EXTRA_EXEC_ARGS` for exec’ing into a running container.

### Geodesic Version 3 Environment Variables

Below is a list of environment variables that may be visible in the shell and were present in Geodesic v3.
Many of these variables are only recognized if you explicitly set or export them prior to running the script.
Others are set and read internally to control optional behaviors.

They are sorted alphabetically, ignoring leading underscores for the purpose of sorting. Variables marked with an
asterisk (*) are either deprecated or removed in Geodesic v4 and should not be relied on. The description prefix
"Internal:" indicates that the variable is used by Geodesic itself and should not be set or relied on. Other
description prefixes such as "AWS SDK:" or "bash:" indicate that these variables are used by the prefixed component
and not Geodesic itself.

| Variable                            | Description                                                                            |
|-------------------------------------|----------------------------------------------------------------------------------------|
| `ASSUME_ROLE`*                      | Internal: Current AWS assume-role name (or profile) in use.                            |
| `ATMOS_BASE_PATH`                   | Base path for Atmos configuration (auto-derived if possible).                          |
| `AWS_CONFIG_FILE`                   | AWS SDK: Specifies a non-default location for the config file                          |
| `AWS_DEFAULT_REGION`                | AWS SDK: Can override the region setting in the config file                            |
| `AWS_DEFAULT_SHORT_REGION`          | Shortened form of the AWS region (e.g., usw2).                                         |
| `AWS_MFA_PROFILE`*                  | Name of the AWS MFA profile for the mfa() function.                                    |
| `AWS_REGION_ABBREVIATION_TYPE`      | Determines how the AWS region name is shortened (e.g., "fixed").                       |
| `AWS_SHARED_CREDENTIALS_FILE`       | AWS SDK: Specifies a non-default location for the credentials file                     |
| `BANNER`                            | Custom banner text shown on shell startup.                                             |
| `BANNER_COLOR`                      | ANSI color (escape code) for the banner text. Defaults to cyan.                        |
| `BANNER_COMMAND`                    | Command used to display the banner. Defaults to figurine).                             |
| `BANNER_FONT`                       | Font to use when BANNER_COMMAND=figurine.                                              |
| `DOCKER_IMAGE`                      | Docker image name (repo) in use. Used for configuring customizations.                  |
| `FZF_COLORS`                        | `fzf`: Chooses the color scheme for the `fzf` interface.                               |
| `GEODESIC_AWS_HOME`                 | Docker ARG: Path to the .aws directory (credentials, config) Geodesic should use.      |
| `GEODESIC_AWS_ROLE_CACHE`           | Internal: Keeps a fingerprint of AWS credentials to update the prompt efficiently.     |
| `GEODESIC_BINDFS_OPTIONS`           | Extra options passed to bindfs for file ownership mapping.                             |
| `GEODESIC_CONFIG_HOME`              | Base directory for user customizations. Before v4, defaults to /localhost/.geodesic.   |
| `GEODESIC_CUSTOMIZATION_DISABLED`   | If set to anything but "false", disables user customizations.                          |
| `GEODESIC_HOST_BINDFS_ENABLED`*     | Deprecated (use `MAP_FILE_OWNERSHIP` instead): Enables file ownership mapping.         |
| `GEODESIC_HOST_CWD`*                | Host’s current working directory (used to set container’s initial cd).                 |
| `GEODESIC_HOST_GID`                 | Host group ID for file ownership user/group mapping.                                   |
| `GEODESIC_HOST_UID`                 | Host user ID for file ownership user/group mapping.                                    |
| `GEODESIC_LOCALHOST`*               | Obsolete: Filesystem path to the host mount (/localhost).                              |
| `GEODESIC_LOCALHOST_DEVICE`*        | Obsolete, Internal: Device info for /localhost (helps detect host vs container paths). |
| `GEODESIC_LOCALHOST_MAPPED_DEVICE`* | Obsolete, Internal: Device info if /localhost is mounted via bindfs.                   |
| `GEODESIC_OS`                       | OS flavor used by Geodesic (e.g., debian or alpine).                                   |
| `GEODESIC_PORT`                     | Port exposed to host, to be used by services like Teleport.                            |
| `GEODESIC_SHELL`                    | Indicates that this is a running Geodesic shell.                                       |
| `GEODESIC_TF_CMD`                   | Terraform command name (e.g., terraform or tofu) for Geodesic to use.                  |
| `GEODESIC_TF_PROMPT_ACTIVE`         | Internal: Whether the custom Terraform prompt is active.                               |
| `GEODESIC_TF_PROMPT_ENABLED`        | Toggles the custom Terraform command-line prompt behavior on/off.                      |
| `GEODESIC_TF_PROMPT_LINE`           | Internal: Holds the prompt string indicating the current Terraform workspace.          |
| `GEODESIC_TF_PROMPT_TF_NEEDS_INIT`  | Internal: Indicates if the current Terraform directory needs initialization.           |
| `GEODESIC_TRACE`                    | Enables logging/tracing of terminal events (e.g., custom, hist).                       |
| `_GEODESIC_TRACE_CUSTOMIZATION`     | Internal: Enables debug tracing of user customization scripts.                         |
| `GEODESIC_VERSION`                  | Current Geodesic version string.                                                       |
| `GEODESIC_WORKDIR`*                 | Obsolete: Initial working directory for the container (e.g., /conf or /stacks).        |
| `HISTFILE`                          | `bash`: Path to the Bash command-history file.                                         |
| `HISTFILESIZE`                      | `bash`: Maximum number of lines to keep in the history file.                           |
| `HOME`                              | POSIX: Home directory inside the container (mapped if /localhost exists).              |
| `KUBE_PS1_CLUSTER_FUNCTION`         | `kube-ps1`: Custom function for cluster-name display in the `kube-ps1` prompt.         |
| `KUBE_PS1_PREFIX`                   | `kube-ps1`: String displayed to the left of the cluster name in `kube-ps1`.            |
| `KUBECONFIG`                        | `kubectl`: Path to the active Kubernetes config file.                                  |
| `LANG`                              | POSIX: Locale for messages and collation.                                              |
| `LC_ALL`                            | POSIX: Forces a single locale category (C.UTF-8) for everything.                       |
| `LOCAL_HOME`                        | Host user’s $HOME, if mapped into the container.                                       |
| `MOTD_URL`                          | URL for fetching a “message of the day” at shell startup.                              |
| `NAMESPACE`                         | Namespace/environment name shown in the prompt/banner.                                 |
| `PROMPT_COMMAND`                    | `bash`/Internal: Bash hook that runs before each prompt; extended by Geodesic.         |
| `PROMPT_HOOKS`                      | Internal: Array of functions to call in PROMPT_COMMAND for dynamic prompts.            |
| `PROMPT_STYLE`                      | Style of the prompt: plain, fancy, or unicode.                                         |
| `PS1`                               | `bash`: Primary prompt string (the final assembled Bash prompt).                       |
| `SCREEN_SIZE`                       | Internal: Tracks the current terminal screen size as LINES x COLUMNS.                  |
| `SHLVL`                             | `bash`: Shell nesting level (1 for the main shell, higher for subshells).              |
| `SSH_AGENT_CONFIG`*                 | Obsolete: Path to the file storing SSH agent environment variables.                    |
| `SSH_AUTH_SOCK`                     | `ssh`: Socket path for the running SSH agent.                                          |
| `SSH_KEY`*                          | Path to private SSH key file to automatically add to the SSH agent.                    |
| `STAGE`                             | Identifies the environment stage (e.g., dev, prod).                                    |
| `TELEPORT_LOGIN`                    | `teleport`: Username for Teleport-based SSH sessions.                                  |
| `TELEPORT_LOGIN_BIND_ADDR`          | `teleport`: Local bind address for Teleport SAML-based login callbacks.                |
| `TELEPORT_PROXY`                    | `teleport`: Teleport proxy host (defaults to tele.<docker-image-subdomain>).           |
| `TF_PLUGIN_CACHE_DIR`               | `terraform`: Location for the [Terraform Provider Plugin Cache][1].                    |

[1]: https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache
