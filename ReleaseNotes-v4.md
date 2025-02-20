# Geodesic v4.0.0 Release Notes

### Highlights

#### Better Shell Management

##### Equal Treatment for Multiple Shells in a Single Container

A much requested feature, Geodesic no longer exits the container when the first shell exits.
Instead, the container runs until all shells have exited. This means you can now run multiple shells
inside the container and exit them in any order; you no longer have to keep track of which
shell was the first one launched. Unfortunately, this also means that you can no longer
detach and reattach to a shell.

A side benefit of this is that previously, if you had something like `trap handler EXIT` in your
top-level shell, there was a good chance the handler would not run because the shell will
be killed (SIGKILL, `kill -9`) rather than shut down cleanly. Now, there is a much greater
likelihood that the shells will shut down in an orderly manner and run their exit hooks.

##### New Capability for Multiple Shells with One Container per Shell

However, Geodesic now supports another much-requested feature: launching a new container
each time you run Geodesic. This is done by setting the `ONE_SHELL` environment variable to "true"
or passing `--solo` on the command line. This allows you to run multiple versions of Geodesic,
and also allows you to detach from a shell and reattach to it later.

##### External Command to Stop Geodesic

Not a new feature, but one that many people were not aware of: you can kill the running
Geodesic container with the command `geodesic stop`. This will stop the container, and it
will be automatically removed (assuming you started it with `geodesic`). Now, however,
there is the possibility that you will have several running containers. If this is the case,
`geodesic stop` will list the running containers by name. You can then pass the
name as an argument to `geodesic stop` and it will stop that one.

##### Cleanup Commands on Shell Exit and Container Exit

Another old feature few people knew about: you can have Geodesic automatically
run a command when a shell exits. This was done by creating an executable command named
`geodesic_on_exit` and putting it in your `$PATH`. This feature has been enhanced
in two ways:

1. Now you can set the name of the command to run when the shell exits via `ON_SHELL_EXIT`
   (defaults to `geodesic_on_exit`). Also new: the `ON_SHELL_EXIT` command will have available
   to it the short ID and name of the container in which it was running, via the
   environment variables `GEODESIC_EXITING_CONTAINER_ID` and `GEODESIC_EXITING_CONTAINER_NAME`,
   respectively.
2. You can use the new environment variable `ON_CONTAINER_EXIT` to configure a different
   command to run only when the container exits. It will also have the container ID and name
   available to it via the same environment variables.

Be aware that the commands are called on a best-effort basis when the Geodesic
launch wrapper exits. If you detach from a shell, the wrapper will run then and
call `ON_SHELL_EXIT`. If you reattach to the shell, the wrapper is not involved,
so quitting the shell or container will not run the cleanup command.

Alternately, if you quit two shells at nearly the same time, for example by
running `geodesic stop`, the `ON_CONTAINER_EXIT` command may be called twice.
This is because the wrapper calls the command when the container has stopped
before shell exit processing has finished, and both shells fit the criterion.

Now that shells normally exit cleanly (provided you do not
run `docker kill geodesic`), you may find that you get more reliable behavior
out of:

```bash
trap exit_handler EXIT
```

to run on each shell completion.

#### Better Configuration Management

Geodesic now supports configuration files for customizing the launch of the Geodesic container.
Although Geodesic has for a while been [customizable](https://github.com/cloudposse/geodesic/blob/main/docs/customization.md),
the customization you could configure via files were limited to customizations of the
running Docker container. Previously, customizations regarding how Geodesic is launched were difficult to manage.
Now, you can create a `launch-options.sh` file in the Geodesic configuration directories
to customize the launch of the Geodesic container. The directory search path and the
priority of the files are the same as for the other Geodesic customization files.

Note that most of the launch options configure the launching of the Docker container,
and therefore have no effect when you run `geodesic` to start a new shell
inside an already running container. However, you can use the `--solo` option to
force Geodesic to start a new container to pick up the new launch options. You
can also add `ONE_SHELL=true` to the `launch-options.sh` file to force Geodesic to
start a new container each time you run it.

#### Better File System Layout

Geodesic no longer mounts the entire host user's home directory into the container.
This had been a performance problem and was explicitly discouraged by Docker. Now,
Geodesic mounts only specific directories from the host to the container, and you
have full control over which directories are mounted where (with sensible defaults).

Inspired by the [Dev Container](https://containers.dev/), the `/localhost` directory
has been removed, and the host's git root directory is mounted to `/workspace` in the container.
This is all configurable, and some configuration for each project will make it easier to
use multiple projects with Geodesic.

Among other things, this means that your project source directory no longer has to be
under your home directory. You are free to locate it on another drive if you like.

For reasons lost to history, Geodesic set the container user's home directory to `/conf`.
This caused some problems for people who wanted to run Geodesic as a non-root user.
The `/conf` directory has been removed, and the container user's home directory
(as specified in `/etc/passwd`) is now honored. By default, Geodesic launches as the
`root` user, so the default `$HOME` is `/root`.

As before, the host user's home directory path is available in the container as
`$LOCAL_HOME`, and mounted files and directories are available at the same paths
in the container as on the host.

## Breaking Changes

- Previously, `$HOME` was set to `/conf` in the container. This is no longer the case.
  `$HOME` is now set to the shell user's home directory. By default, this is `/root`.
  If you launch a shell in Geodesic as a non-root user, `$HOME` will be set to that user's home directory,
  provided you have properly created the user with `adduser`. **By default, the
  container user will share configuration with the host user by mounting selected host user's
  configuration directories into the container user's home directory, allowing
  bidirectional updates.**

> [!WARNING]
> It is important to be aware that any files from the host directory that are mounted into the container
> will be modifiable by the container user, and those modifications will propagate to the host.
> This includes any files that are implicitly modified by programs running in the container.
> If you need separate configurations for the host and container, you should not use
> `HOMEDIR_MOUNTS` or `HOMEDIR_ADDITIONAL_MOUNTS` to directly mount them into the container's
> home directory. Instead, you use `HOST_MOUNTS` to mount them elsewhere in the container,
> and then use a preferences or override script to copy the files to the appropriate location
> and then modify them if needed. See [docs/customization.md](docs/customization.md) and
> [docs/environment.md](docs/environment.md) for more details.

- Global Git configuration can be in either of 2 places:
  - `~/.config/git/config` - Starting with `git` v2.41 or so, it is the newly preferred location for the global Git configuration.
  - `~/.gitconfig` - This is the old location for the global Git configuration.

  If you have a `~/.gitconfig` file, it will not be accessible to the container by default.
  This may be advantageous if you want to keep your global Git configuration separate from the container.
  If you have a `~/.config/git/config` file, it will be accessible to the container by default,
  and it will be modified if you run `git config --global` from within Geodesic,
  provided you are using a recent enough version of `git`. The version of `git`
  that ships with Debian 12 and Geodesic 4.0.0 is 2.39.5 and does not yet
  appear to support `~/.config/git/config`, but this could change without notice.

- The `/conf` directory no longer exists. Generally, what used to be in `/conf`
  is now in `/root` if it was created in the Geodesic Dockerfile.debian, or in
  `$HOME` (also `/root` by default) if it was created in the Geodesic startup scripts.
- The `conf-directory` command has been removed. It was part of the old `helmfile` support
  but likely had been broken for some time. If you were using it, you will need to
  copy the old file and update it to reflect that `/conf/` no longer exists.
- Support for [Atlantis](https://github.com/runatlantis/atlantis) has not been removed, but
  it is also not being actively maintained or tested, so this release may have issues with Atlantis.
  Among other things, the Atlantis configuration directory previously defaulted to `/conf/atlantis/`, which no longer exists.
  The default has been changed to `/home/atlantis`, but that directory also does not exist by default.
  You should create it along with creating the `atlantis` user in your Dockerfile.
- `/conf/.kube/config` has been moved to `/etc/kubeconfig`. It is installed as
  `/root/.kube/config`, but this is now expected to be hidden by mounting the
  host user's `$HOME/.kube` directory over `/root/.kube`.

<details><summary>Special notes for Spacelift Users (click to reveal)</summary>

If you are using Geodesic with Spacelift, you may need to make some changes to your Dockerfile.
The `spacelift` user is required by Spacelift if you want to run this image as a Spacelift runner image.
If you previously were installing `/rootfs/conf/.kube/config` somewhere like `$HOME/.kube/`,
you should now be installing `/rootfs/etc/kubeconfig` instead.

```dockerfile
# `spacelift` user with uid=1983 is required by Spacelift if we want to run this image as Spacelift runner image
# https://docs.spacelift.io/concepts/worker-pools#custom-runner-images
# https://docs.spacelift.io/integrations/docker#customizing-the-runner-image
RUN adduser --disabled-password --home /home/spacelift --no-create-home --uid 1983 --gecos "" spacelift
# Spacelift running under EKS needs to be able to dynamically update its AWS configuration.
# This includes creating temp files under /etc/aws-config/ and modifying aws-config-spacelift.
# We create /home/spacelift separately rather than via adduser to avoid getting default files like .bashrc installed.
# NOTE: The following assumes that Spacelift is getting its AWS configuration from /etc/aws-config/aws-config-spacelift
# which must exist or this line will fail. If you are storing its configuration elsewhere, you will need to adjust this line.
RUN mkdir /home/spacelift && \
    chown spacelift:spacelift /etc/aws-config/aws-config-spacelift /home/spacelift && \
    chgrp spacelift /etc/aws-config/ && \
    chmod 775 /etc/aws-config/

 # Give Spacelift an empty KUBECONFIG file to suppress some errors and warnings
 RUN if [ -d /conf/.kube ]; then cp -a /conf/.kube /home/spacelift/.kube; \
    else mkdir -p /home/spacelift/.kube && cp /etc/kubeconfig /home/spacelift/.kube/config; fi && \
    chown -R spacelift:spacelift /home/spacelift/.kube && \
    chmod 700 /home/spacelift/.kube && \
    chmod 600 /home/spacelift/.kube/config
```

You may also have had a script under `rootfs/etc/profile.d` that set up `$HOME` like this:

```bash
{ [[ -z $HOME ]] || [[ $HOME == "/root" ]]; } && (( $(id -u) == 0 )) && export HOME=/conf
```

You can delete that line, as `$HOME` is now set to the shell user's home directory by default,
or you can replace it with the following, which works with both Geodesic v3 and v4:

```bash
[[ -z $HOME ]] && HOME="$(getent passwd $(id -un) | cut -d: -f6)"
[[ $HOME == "/root" ]] && (( $(id -u) == 0 )) && [[ -d /conf ]] && export HOME=/conf
```

</details>

- Previously, if you exited the shell that launched Geodesic, the container would exit,
  killing any other running shells. Now, the container will not exit until all shells have exited.
  As a side effect, you can no longer reattach to a shell that you have detached from.
  You can get something closer to the old behavior by setting `ONE_SHELL=true`.
  See [New Default Behavior for Multiple Shells](#new-default-behavior-for-multiple-shells) below
  for more details.

- Previously, the entire host user's home directory was mounted into the container under `/localhost`,
  making everything in the host user's home directory available to the container.
  Now, only specific directories are mounted, and they are mounted in the container user's
  `$HOME` directory. The default directories are `.aws`, `.config`, `.emacs.d`,
  `.geodesic`, `.kube`, `.ssh`, and `.terraform.d`. You can add additional directories by setting
  the `HOMEDIR_ADDITIONAL_MOUNTS` environment variable. See [The Home Directory](#the-home-directory) below
  for more details.

- Previously, preferences and overrides files could be placed directly in the `$GEODESIC_CONFIG_HOME`
  directory. Now they must be placed in `$GEODESIC_CONFIG_HOME/defaults` or a
  Docker image-specific subdirectory. Only the `history` file can be placed directly in the
  `$GEODESIC_CONFIG_HOME` directory.

- Previously, environment variables inside the container could be set in the `~/.geodesic/env` file,
  which was passed to Docker via `--env-file`. This file is now ignored. Instead, you should
  set environment variables in the customization preferences and overrides.

- The `/localhost` directory no longer exists. This used to be the single mount point
  for the host filesystem, and the host user's entire `$HOME` directory was mounted there.
  Now, we no longer mount the entire `$HOME` directory tree into the container. Instead,
  we mount specific directories from the host to the container.
  - Configuration directories directly under the host user's `$HOME` directory
    (such as `.aws` or `.config`) are mounted to the container user's `$HOME`
    directory.
  - The git repository root directory for the project is mounted to the container's `/workspace` directory.
  - Additional directories can be mounted from the host to the container by setting
    the `HOST_MOUNTS` environment variable.

  If you were relying on the `/localhost` directory, it would be best to update your scripts to use
  either `$HOME`, `$WORKSPACE_MOUNT`, or `$WORKSPACE_FOLDER` as appropriate. As a temporary workaround,
  you can run `ln -s "$LOCAL_HOME" /localhost` in your customizations.

- By default, Geodesic automatically sets `TF_PLUGIN_CACHE_DIR` to `"${HOME}/.terraform.d/plugin-cache"`
  to provide a location for the [Terraform Provider Plugin Cache](https://developer.hashicorp.com/terraform/cli/config/config-file#provider-plugin-cache).
  This is a location on the host filesystem, allowing the cache to be shared between the host and the container,
  and to persist between container runs. This saves significant time and bandwidth, and we highly recommend
  using the plugin cache, which is why we have been setting it for years.
  However, the way this was implemented, it was difficult for users to opt-out of the plugin cache altogether.
  To accommodate those users while maintaining backward compatibility,
  Geodesic now checks, and if `TF_PLUGIN_CACHE_DIR` is set empty, or to "false" or "disabled",
  Geodesic unsets the variable, allowing users to avoid having a cache directory.

- Previously, you could have Geodesic perform file ownership mapping between host and container
  by setting `GEODESIC_HOST_BINDFS_ENABLED=true`; this variable is now deprecated.
  Use `MAP_FILE_OWNERSHIP=true` instead. This feature is disabled by default and can
  cause issues if enabled unnecessarily, but it is useful if you are having file ownership issues.
  See [Files Written to Mounted Host Home Directory Owned by Root User](https://github.com/cloudposse/geodesic/issues/594)
  for more details.

### Obsolete and Deprecated Features

#### Custom SSH Support Removed

When Geodesic was first created, there was no way to share the SSH agent socket between the host and the container.
As a result, Geodesic provided custom SSH support, launching an SSH agent and reading configuration and keys from the host.
Now that Docker supports sharing the SSH agent socket, this custom SSH support is no longer necessary.
If the `SSH_AUTH_SOCK` environment variable is set on the host, it will be used by Docker, and the
Docker container will have access to the host SSH agent. The host `$HOME/.ssh` directory will also
be mounted automatically (unless you suppress it), so the container will have access to the host's SSH keys
and configuration, giving you a choice of how to manage your SSH keys.

We recommend you use the host's security mechanisms to secure your SSH keys, and add them to the host's
SSH agent to make them accessible to the container.

#### Automatic MFA Support Removed

The `mfa` command and `oathtool` were removed.  The `mfa` command was a wrapper around `oathtool`
to generate TOTP codes. It was removed because:

- We did not have a secure place to store the TOTP key.
  - It was being stored in a plaintext file
  - It was being stored in `${AWS_DATA_PATH}/${profile}.mfa` which is wrong on several levels:
    1. `$AWS_DATA_PATH` is a `PATH`-like list of directories, not a single directory
    2. `$AWS_DATA_PATH` is meant to direct the AWS SDK to [directories from which to load Python models](https://github.com/boto/botocore/blob/cac78632cabddbc7b64f63d99d419fe16917e09b/botocore/loaders.py#L33), not for storing user data
    3. Actually storing the key in `${AWS_DATA_PATH}/${profile}.mfa` can cause problems for the AWS SDK
- We believe there are better ways to manage MFA, such as 1Password.
- If you still want to use `oathtool`, you can install it yourself. It is very easy to use.

### Internal changes less likely to affect users

- Previously, Geodesic attempted to duplicate host file paths inside the container
  using symbolic links. Now Geodesic uses bind mounts instead. This should not affect
  the user, but it does require the `SYS_ADMIN` capability.
  Geodesic has always run with the `--privileged` flag, which includes `SYS_ADMIN`, so
  this only affects people who had removed the `--privileged` flag somehow.

## New Container File System Layout

Geodesic v4.0.0 introduces a new file system layout for the Geodesic container,
inspired by the [Dev Container](https://containers.dev/) standard.

### The Old Layout

Previously, the host user's entire home directory was mounted into the container
under `/localhost`. This was done to allow the container to access the host user's
configuration files, such as `.aws` and `.ssh`. However, this had some major drawbacks,
the main one being that Docker had to map all of the user's files and directories into the
container, including, on macOS, Docker's own virtual disk and other dynamic files.
This caused major performance problems in some cases.

Previously the home directory for the container user was forced to be `/conf`, and files
and directories were linked from `/localhost` to `/conf`. This was done to allow for a single
host mount, back when host mounts were expensive. This was also problematic, as `/conf` was
owned by `root`, and if you wanted to run the Geodesic image as a non-root user, you
had to take extra steps to manage the permissions of `/conf` and its contents.

### The New Layout

#### The Home Directory

A set of directories are mounted from the user's home directory on the host to the container user's
home directory. These are meant to be directories that contain configuration files that the container's
users will need to access. Project source directories and other directories that are not meant to be
used as configuration directories should not be mounted this way. Mount the project source directories
into the container's workspace instead, and mount other directories via the `HOST_MOUNTS` environment variable,
both of which are described after this section.

These directories are specified as a comma-separated list of directories (or files) relative to the host user's home directory.
If items in the list are not present on the host, they will be silently ignored.

- `HOMEDIR_MOUNTS` is a list of directories to mount. It is set by default to `".aws,.config,.emacs.d,.geodesic,.kube,.ssh,.terraform.d"`.
  If you set it to something else, it will replace the default list. Ensure that your Geodesic configuration directory
  (default is `$HOME/.config/geodesic`) is mounted.
- `HOMEDIR_ADDITIONAL_MOUNTS` is a list of additional directories to mount. It is appended to the
  `HOMEDIR_MOUNTS` list of directories to mount. This allows you to add to the defaults without overriding them.

Note that you can mount files this way, but there are issues with that, especially when mapping file ownership.

Many files that used to be placed directly in the `/conf` directory can now be placed in subdirectories.
Many applications now support the `XDG Base Directory Specification`, which specifies that configuration
files should be placed in `$XDG_CONFIG_HOME` (defaults to `~/.config/`). This directory is mounted by default.

- `~/.gitconfig` can be moved to `~/.config/git/config`. If you mount `~/.gitconfig` directly, and have file ownership
  mapping enabled, `git config` will not be able to modify the file. Instead, you should mount `~/.config/` and the
  `git/config` inside will work as expected.
- `~/.bash_profile` can be moved to `~/.bash_profile.d/` and sourced from there. however, we do not recommend this, and we do not
  mount `~/.bash_profile.d` by default. Instead, we recommend you put scripts you want to run inside Geodesic in
  `~/.config/geodesic/defaults/preferences.d/` where they will be sourced automatically. If you want to share
  files between the host and Geodesic, you can use symbolic links, but keep in mind that they must resolve properly in
  the container, and the target files must be in a directory that is mounted into the container. You can mount
  `~/.bash_profile.d` into the container by setting `HOMEDIR_ADDITIONAL_MOUNTS=".bash_profile.d"`.
- `~/.bashrc` can be moved to `~/.bashrc.d/` and sourced from there. The same caveats apply as for `~/.bash_profile`.
- `~/.emacs` can be moved into its current preferred location, `~/.emacs.d/init.el`.

#### The Host Mounts

You can mount any additional directories from the host to the container by setting the `HOST_MOUNTS` environment variable.
This is a comma-separated list of directories to mount, in the format `absolute_host_path[:container_path]`. If the container path is not specified,
it will be the same as the host path. The host path name must be absolute, and `~` is not acceptable.
If you want to place directories under the container user's home directory, use `HOMEDIR_ADDITIONAL_MOUNTS`
as described above.

Unfortunately, since the colon (`:`) is meaningful to Docker, you cannot mount directories with colons in their names,
and you cannot separate directories with colons. This list must be separated with commas.

#### The Workspace

The workspace is where the code on the host lives, and is mounted into the container.
This is controlled by several environment variables, all of which have defaults
settings that can be overridden.

As always, you can configure the environment variables on the command line with `--var=value`,
but as a convenience, you can also override `WORKSPACE_FOLDER_HOST_DIR` with `--workspace=dir`.

tl;dr: Either launch Geodesic from the root of your project, or set `WORKSPACE_FOLDER_HOST_DIR` in your `launch-options.sh` file
to the root of your project. (See [Launch Options Files](#launch-options-files) below for details.)
If you do this, you can launch Geodesic from any directory and have the correct directory be the workspace.

| Variable                    | Description                                                                                               |
|-----------------------------|-----------------------------------------------------------------------------------------------------------|
| `WORKSPACE_FOLDER_HOST_DIR` | The directory on the host that is the root of the project.                                                |
| `WORKSPACE_MOUNT_HOST_DIR`  | The directory on the host that is mounted into the container to make the source code accessible.          |
| `WORKSPACE_MOUNT`           | The directory in the container where the `WORKSPACE_MOUNT_HOST_DIR` is mounted. Defaults to `/workspace`. |
| `WORKSPACE_FOLDER`          | The directory in the container that is considered the root of the project.                                |

The variables are set as follows:

- If you set `WORKSPACE_FOLDER_HOST_DIR` in the environment, that directory will be used as the working directory. It must be an
  absolute path: `$HOME/path` is acceptable, `~/path` is not. You can set this in the `launch-options.sh` file for
  each image you use, and then you can launch Geodesic from any directory and have the correct directory be the workspace.
  If not set, `WORKSPACE_FOLDER_HOST_DIR` defaults to the current working directory, from where Geodesic was launched.

- If you set `WORKSPACE_MOUNT_HOST_DIR` in the environment, it must be either the same as `WORKSPACE_FOLDER_HOST_DIR` or
  a parent of that directory. This directory will be mounted into the container as `WORKSPACE_MOUNT`. If not set:

  - If `WORKSPACE_FOLDER_HOST_DIR` is inside a Git repository, `WORKSPACE_MOUNT_HOST_DIR` will be set to the root of that repository
  - If `WORKSPACE_FOLDER_HOST_DIR` is not inside a Git repository, `WORKSPACE_MOUNT_HOST_DIR` will be set to `WORKSPACE_FOLDER_HOST_DIR`

- Unless explicitly set (not recommended), `WORKSPACE_FOLDER_HOST_DIR`, relative to the parent of `WORKSPACE_MOUNT_HOST_DIR`, will be communicated
  to the container as `WORKSPACE_FOLDER` and considered the working directory for the container.
- A symbolic link will be created in the container, so that the host value of `WORKSPACE_FOLDER_HOST_DIR` will
  reference the `WORKSPACE_FOLDER`.

### Fixing File Ownership Issues

Depending on the way you installed Docker, you may have file ownership issues with the files created
from within the container on the host. The default Geodesic user is `root` and if Docker is not translating
file ownership properly, the files will be owned by `root` on the host. This can be fixed by running Docker
in "rootless" mode, but that is not always practical, so Geodesic has special support to handle this case.

This support used to be enabled by setting `GEODESIC_HOST_BINDFS_ENABLED=true`, but this is now deprecated.
Instead, enable it by setting `MAP_FILE_OWNERSHIP=true`. This will cause Geodesic to use `bindfs` to map the
file ownership between the host and the container. Please note, however, that if Docker is properly translating
file ownership, this setting will cause, rather than fix, file ownership problems, so only use it if needed.
It is disabled by default, because current macOS and best practice Linux Docker installations do not need it.

## New Features

### Command-Line Options

Geodesic documentation has shown (and for the moment, continues to show)
Geodesic options as settings of shell environment variables. This is because Geodesic
is launched by a `bash` script, and then runs a `bash` shell inside the container.
In this document, we take care to differentiate between options that apply to the
launch script (sometimes referred to as the "wrapper") and options that apply to the
shell inside the container.

What has always been true, but never clearly spelled out, is that the options that
apply to the launch script can also be set as command-line options. Convert the
environment variable to lower case, optionally replace the `_` with `-`, and prefix
it with `--` and you have the command line option. For example, `ONE_SHELL=false` becomes
`--solo=false`. For boolean options, you can leave out the value, so `ONE_SHELL=true`
becomes `--solo`.

To avoid tedious redundancy, we will not usually repeat the command-line options in the
documentation. Instead, we will refer to the environment variable, and you can
convert it to a command-line option as described above. Just remember that they
only apply to launch options, not to configuration of the shell inside the container.

### New Default Behavior for Multiple Shells

Previously, when you launched Geodesic, it would launch a new shell as PID 1.
If you tried to launch Geodesic again, it would not start a new container, but would
instead exec into the container, launching a new shell. This was done to avoid the
overhead of starting a new container each time you wanted a new shell, and has some
advantages and disadvantages with all the shells sharing the same container.
One disadvantage was that if you exited the first shell, the container would exit,
killing any other shells running inside the container. Another disadvantage,
or at least odd behavior, is that if you detached from the first shell, you could
reattach to it later, but if you detached from a shell launched by exec, you could
not reattach to it. Attempting to reattach to it would attach to the first shell,
and you would have 2 terminals sharing the same shell, while the detached shell
would remain abandoned.

Now, by default, when you launch Geodesic, it launches a tiny init process as PID 1. This init process
monitors the shells running inside the container, and does not exit until all the shells exit.
So now if you quit the first shell while other shells are running, the container will not exit.

One consequence of this change is that if you detach from any shell, even the first one, you will not be able to
reattach to it. `docker attach` will connect you to the init process, not the shell. So we semi-disable detaching from
the shell by setting an unusual string for the `detachKeys`.

### New Option for One Container Per Shell

An alternative to this new default behavior is to launch a new container each time you run Geodesic.
This is done by setting the `ONE_SHELL` environment variable to "true" in your
`launch-options.sh` file, or using `--solo` on the command line. This will cause the wrapper
to launch a new container each time you run it.

The 2 main advantages of this are:

1. You can run multiple versions of Geodesic at the same time. This is useful for testing new versions.
2. You can detach from a shell and reattach to it later.

### New Options for Cleanup Scripts

Previously, when the wrapper that launches Geodesic exited, it would run a cleanup script
named `geodesic_on_exit` if it existed. This name was hard coded and not configurable.

Now, the name of the cleanup script is configurable, and the script makes a distinction between
two events:

1. ON_SHELL_EXIT: When a shell exits but the container is still running. Defaults to no script.
2. ON_CONTAINER_EXIT: When the container exits. Defaults to `geodesic_on_exit`.

The caveat here is that these scripts are run when the wrapper exits, not necessarily
when the shell or container exits. This means that if you detach from a shell, the wrapper
will run `$ON_SHELL_EXIT`. If you reattach to the shell, the wrapper is not involved,
so quitting the shell or container will not run the cleanup script.

### New Location for Geodesic Configuration Files

Previously, all Geodesic configuration was stored in the `~/.geodesic` directory.
This has been changed to `$XDG_CONFIG_HOME/geodesic` which defaults to `~/.config/geodesic`.
This change was made to follow the
[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

If the `$XDG_CONFIG_HOME/geodesic` directory does not exist, Geodesic will
continue to use the `~/.geodesic` directory. If the `$XDG_CONFIG_HOME/geodesic` directory does exist,
the `~/.geodesic` directory will be ignored.

Previously, environment variables inside the container could be set in the `~/.geodesic/env` file,
which was passed to Docker via `--env-file`. This file is now ignored. Instead, you should
set environment variables in the customization preferences and overrides.

### New Customization Options

As explained in the [Customizing Geodesic](/docs/customization.md) documentation,
there are several ways to customize Geodesic. However, until now, most of these customizations
only applied to customizing the shell inside the Geodesic container. Customizing the
launch of the Geodesic container itself was more difficult.

#### Launch Options Files

Geodesic now supports launch options files that customize the launch of the Geodesic container.
Geodesic is launched by a `bash` script and can be customized by setting environment variables.
Using the same directory structure as the Geodesic configuration files, you can create a file
`launch-options.sh` that will be sourced by the script after the defaults are configured but before
they are used. The searched directories depend on the name of the Docker image being launched.
All `launch-options.sh` files are sourced in the order they are found, meaning later ones override earlier ones.
With the configuration directory `$GEODESIC_CONFIG_HOME` (defaults to `$XDG_CONFIG_HOME/geodesic`) and
an image named `ghcr.io/cloudposse/geodesic:4.0.0-debian`, the directories searched, in order, are:

1. `$GEODESIC_CONFIG_HOME/defaults/`
2. `$GEODESIC_CONFIG_HOME/cloudposse/`
3. `$GEODESIC_CONFIG_HOME/geodesic/`
4. `$GEODESIC_CONFIG_HOME/cloudposse/geodesic/`

The registry (`ghcr.io/` in the example) is ignored when searching for the `launch-options.sh` file.

If the `$GEODESIC_CONFIG_HOME/launch-options.sh` file directly changes the `DOCKER_IMAGE` variable, it will change the
directories being searched in steps 2-4. Later changes, or setting `GEODESIC_IMAGE`, will not change
the directories being searched.

#### New Customization Command-Line Options

Some line options regarding customization have been added:

1. `--no-custom` (or `--no-customization`, or `--geodesic-customization-disabled`) will disable all user-specific
   customizations. This is equivalent to setting `GEODESIC_CUSTOMIZATION_DISABLED=true`. This is useful for
   "works in my environment" testing, where you want to disable all customizations to see if the problem is in the
   customizations or in the base image. Note that this does not disable changes made by `launch-options.sh`.
2. `--trace` will enable tracing the Geodesic script as it performs customizations. Equivalent to `--trace=custom`.
3. `--trace="custom terminal hist` will enable tracing of the customizations, terminal configuration (mainly with respect
   to light/dark mode support), and the determination of which Bash history file to use, respectively.
   You can use these options in any combination.
4. `--dark` and `--light` will set the terminal theme to dark or light, respectively, disabling attempts to automatically detect it.
   This is mainly useful if the automatic detection is not working.

## Dark mode support

Geodesic's limited color handling had initially assumed terminals are in light mode.
Support for terminals being in dark mode was introduced in Geodesic v2.10.0,
but was not previously well documented. There have also been some enhancements
since then. The following describes the state of support as of v4.0.0.

### Switching between light and dark themes

Geodesic provides basic support for terminal dark and light themes.
Primarily, this is used to ensure Geodesic's colored output is readable in both modes,
for example, black in light mode and white in dark mode.

While there are standard ways to detect the terminal color settings, they are not
universally supported, and various terminals have their quirks. As a result, color
detection is not always reliable, and you may see errors or 'garbage' output
during startup, especially if you are not using a widely popular terminal.

#### Initial theme detection

It is critical to detect the terminal theme when Geodesic starts. This is done
by default, and can only be disabled by specifying the desired theme,
"light" or "dark", via `--light` or `--dark` command line options,
or by setting the GEODESIC_TERM_THEME environment variable to "light" or "dark". This
must be set in the environment before Geodesic starts, e.g. in the `launch-options.sh` file.

#### Detecting changes in theme while running (experimental)

You may have your terminal set to automatically switch between light and dark themes
based on the time of day, or you may manually switch between themes. Unfortunately,
there is no standard way for a shell to be notified when a terminal's theme changes. Furthermore,
due to the inherent challenges of detecting terminal themes, automatic
detection of changes in the terminal theme has too often injected disruptive characters and messages
into the user's workflow. As a result, Geodesic by default does not attempt to detect changes
in the terminal theme while running.

If you want to manually notify Geodesic of the change, you can call

```bash
set-terminal-theme [light|dark]
```

If you provide an argument, it will set the terminal theme to that argument. If you do not provide an argument,
it will attempt to determine the terminal theme itself.

You can query Geodesic for its cached theme setting by running

```bash
get-terminal-theme
```

Some terminals notify the shell of color changes by sending a `SIGWINCH` signal.
Geodesic also sends this signal to its shell when it detects a change in the size of the window.
You can set the environment variable `GEODESIC_TERM_THEME_AUTO=enabled` to enable
Geodesic to listen for this signal and update the theme when it is received.
Beware that while updates are called from the prompt command hook, we have seen many
instances where the terminal does not respond to the query about its color settings
promptly, resulting in failed detection, and the response being written to the
terminal command line. It might look something like `^[]11;rgb:fdfd/f6f5/e3e3^G`.

Be aware that this is not an area where good solutions exist, which is why
this feature is disabled by default. Unlike with the initial theme detection,
this is not an area where we are investing effort to improve.

Changing Geodesic's theme does not change anything already on the screen. It only affects
future output.

#### Named text color helpers

To help you take advantage of the terminal color theme support, Geodesic provides a set of named text color helpers.
They are defined as functions that output all their arguments in the named mode.
The named colors are

- red
- green
- yellow
- cyan

Note: yellow is problematic. To begin with, "yellow" is not necessarily yellow,
it varies with the terminal theme, and would be better named "caution" or "info".
In addition, it is too light to be used in light mode, so we substitute magenta instead.
We intentionally avoid `blue` and `magenta` because they are problematic in dark mode,
and because we use magenta as a substitute for yellow in light mode.
We also avoid `black` and `white` because they are completely unsuitable for use in
an environment where the terminal theme can switch between light and dark. Instead,
we take care to use the terminal's stated foreground and background colors, which
the terminal itself will change (including text already on the screen) when changing its theme.

Each of these colors has 4 variations. Using "red" as an example, they would be:

- red
- bold-red
- red-n
- bold-red-n

The "bold-color" version outputs text in the bold (or "emphasis") version of the color.

The "-n" means no newline is output after the text. These versions also include non-printing delimiters around the
non-printing text, making them suitable for use in PS1 prompts.

Note that the newline in the plain versions is stripped if run via command substitution, so

```bash
echo "$(red "Hello") World"
```

will not have a newline between "Hello" and "World".

The remaining ANSI colors, black, white, blue, and magenta, are not directly provided as named helpers to
discourage their use. They are available via the `_geodesic_color` function, which takes
the same kind of color name as the named helpers as its first argument, and then outputs
the rest of its arguments in that color. For example,

```bash
_geodesic_color bold-magenta Hello, World
```

These colors are not provided as named helpers because they are problematic, and
we want to discourage their use. Nevertheless, you may prefer to use the
`_geodesic_color` function to color text in these colors, because of the
dark mode support.

- In light mode, yellow is too light to be used, so it is replaced with magenta.
  We therefore discourage using magenta as it will not be distinguished from yellow in light mode.
- In dark mode, blue is problematic, so it is replaced with cyan. Also, white and black are swapped.

## Updated Documentation

The [customization](/docs/customization.md) documentation has been updated to reflect the new
features and changes in Geodesic v4.0.0.

The [environment variables](/docs/environment.md) documentation has been added to document the
shell environment variables Geodesic uses for customization and operation.

The [wrapper](/docs/wrapper.md) documentation has been added to explain what is meant
when other documentation refers to "the wrapper".

### Environment Variable Changes

For full documentation of environment variables, see the [Environment Variables](/docs/environment.md) document.

V4 changes:

- `GEODESIC_LOCALHOST` prefixed variables have been removed.
- `HOME` has changed from `/conf` to the container user's home directory as configured in `/etc/passwd`. For the
  default user of `root`, this is `/root`.
- Variables that had defaults referencing `/localhost` now generally reference `$HOME` instead.

- `HOMEDIR_MOUNTS` and `HOMEDIR_ADDITIONAL_MOUNTS` are comma-separated lists of directories relative to the host user's home directory
  to mount into the container under the container user's home directory. `HOMEDIR_MOUNTS` has a default list of
  directories to mount. `HOMEDIR_ADDITIONAL_MOUNTS` is appended to the `HOMEDIR_MOUNTS` list so you can easily
  add to the defaults without overriding them.
- `HOST_MOUNTS` is a list of mounts from the host to the container. It has the format
  `host_path[:container_path]`. If the container_path is not specified, it is assumed to be the same as the host_path.
  This list excludes the home directory, which is handled separately.

- `WORKSPACE_MOUNT_HOST_DIR` is the host directory where the project will be mounted. Analogous to the source of Dev Container's
  `workspaceMount`. Typically, this is a Git repository root.
- `WORKSPACE_MOUNT` is the container path where `WORKSPACE_MOUNT_HOST_DIR` will be mounted. Analogous to the target of Dev Container's
  `workspaceMount`. Defaults to `/workspace`, which is the default for a Dev Container, but you may want to set it to
  something like your project name or git repository name for visibility in the container.
- `WORKSPACE_FOLDER_HOST_DIR` is the base directory of the project on the host. Analogous to the target of Dev Container's
  `workspaceFolder`. Typically, this is the same as `WORKSPACE_MOUNT`, but may be a subdirectory if the Git repository is
  a "monorepo" containing multiple projects. It must be an absolute path either equal to or a subdirectory of `WORKSPACE_MOUNT_HOST_DIR`.
  - Setting `WORKSPACE_FOLDER_HOST_DIR` in your Docker-image-specific `launch-options.sh` will allow you to launch your project's
    Geodesic app from any working directory and have the correct configuration inside Geodesic.
- `WORKSPACE_FOLDER` is the base directory of the project inside the container. Analogous to the target of Dev Container's
  `workspaceFolder`. Typically, this is the same as `WORKSPACE_MOUNT`, but may be a subdirectory if, for example, the Git repository is
  a "monorepo" containing multiple projects. It must be an absolute path either equal to or a subdirectory of `WORKSPACE_FOLDER_HOST_DIR`.
- `GEODESIC_TERM_THEME` is normally unset. Set it to "light" or "dark" _before launching Geodesic_ to disable the initial attempt at automatic terminal light/dark theme detection, and use the set value instead.
- `GEODESIC_TERM_THEME_AUTO` is normally unset. Set it to "enabled" to enable automatic attempts to detect changes in terminal light/dark theme. This feature should be considered experimental and may not work as expected.
