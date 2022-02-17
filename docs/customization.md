---
title: Customization(5) | Geodesic
author:
- Nuru
date: March 2019
---

## NAME

Customization - How to customize Geodesic at launch time

## SYNOPSIS
 
Several features of Geodesic can be customized at launch time (rather than
during the build of the Docker image) so that people can share an image
yet still have things set up the way they like. This document describes
how to configure the customization.

## DESCRIPTION

A great deal of customization can be implemented by placing shell scripts 
on the host computer, to be read either at the start of `bash` profile 
script processing or at the end of it. These shell scripts can set up environment variables, command
aliases, shell functions, etc. and through setting environment variables, can cause Geodesic to 
enable or disable certain features.

Due to technical limitations, there are a small number of options 
that can only be controlled via command line options or corresponding (exported) 
shell environment variables set in the user's shell before launching 
Geodesic via the wrapper script (which is the default and recommended way to launch Geodesic).

Users can also choose whether to have a single `bash` history file 
for all containers or to have separate history files.

### Command line options (also environment variables)

Geodesic accepts a small number of command line options, which can also be
set by corresponding (exported) shell environment variables. In all cases, 
the command line options must be introduced with double dashes and be
set via `=`. Boolean options can be set `=true` with no argument on the command line.
Command line options are lower case with words separated by dashes,
while environment variables are upper case with words separated by underscores.

Valid:
```bash
geodesic --env-file=~/.geodesic/extra-envs
ENV_FILE=~/.geodesic/extra_envs geodesic
geodesic --geodesic-host-bindfs-enabled
```

Not valid:
```bash
geodesic --env-file ~/.geodesic/extra-envs
env-file=~/.geodesic/extra-envs
ENV-FILE=~/.geodesic/extra-envs
GEODESIC_HOST_BINDFS_ENABLED= geodesic
```

At the moment, underscores are accepted instead of dashes in command line arguments,
but this behavior should not be relied on:

Works, but not officially supported:
```bash
geodesic --env-file=~/.geodesic/extra_envs
```

TODO: Document all the command line options in [geodesic(1)](geodesic.md)

### Root directory for configuration 

All configuration files are stored under `$GEODESIC_CONFIG_HOME`, which defaults to `/localhost/.geodesic`. 
At this time, `/localhost` is mapped to the host `$HOME` directory and this cannot be configured yet, 
so all configuration files must be under `$HOME`, but within that limitation they can be placed anywhere. 
So if you set `$GEODESIC_CONFIG_HOME` to `/localhost/work/config/geodesic`, 
then files would go in `~/work/config/geodesic/` and below on your Docker host machine.

### Resources

There are currently 5 Resources used for configuration:
- Preferences, which are shell scripts loaded very early in the launch of the Geodesic shell. 
- Overrides, which are shell scripts loaded very late in the launch of the Geodesic shell.
- `bash` history files, which store `bash` command line history.
- A file of environment variable settings passed to `docker --env-file`
- Command-line options (which can also be set by correspondingly named shell environment variables)

Additionally, when Geodesic exits normally, it will run the host command `geodesic_on_exit`
if it is available. This is intended to be a script that you write and install
anywhere on your PATH to do whatever cleanup you want. For example, change the window title.

#### Preferences and Overrides

Both preferences and overrides can be either a single file, named `preferences` and `overrides` respectively, 
or can be a collection of files in directories named `preferences.d` and `overrides.d`. 
If they are directories, all the visible files in the directories will be sourced, 
except for hidden files and files with names matching the `GEODESIC_AUTO_LOAD_EXCLUSIONS` regex, 
which defaults to `(~|.bak|.log|.old|.orig|.disabled)$`. 

#### History files

`bash` history is always stored in a single file named `history`, never a directory of files
nor files with any other name. If you want to use a separate history file for one
Geodesic-based Docker image not shared by other Geodesic-based Docker images, you 
must create an empty `history` file in the image-specific configuration directory (see below).

#### Environment file

Geodesic passes a single argument to Docker's `--env-file` option when launching 
via the installed wrapper script. By default, that file is `~/.geodesic/env`
but that file name can be set via the `--geodesic-default-env-file` command line
option or the `GEODESIC_DEFAULT_ENV_FILE` environment variable.

A second environment file can be specified in addition to the default via the
`--env-file` command line option or `ENV_FILE` 

### Configuration by file placement
Resources can be in several places, and will be loaded from most general to most specific, according to the name of the docker container image. 

- The most general resources are the ones directly in `$GEODESIC_CONFIG_HOME`. These are applied first. To keep the top-level directory less cluttered and to avoid name clashes, you can put them in a subdirectory named `defaults`. If that subdirectory exists, then `GEODESIC_CONFIG_HOME ` itself is not searched.
- The `DOCKER_IMAGE` name is then parsed. Everything before the final `/` is considered the "company" name and everything after is, following the Cloudposse reference architecture, referred to as the "stage" name. So for the `DOCKER_IMAGE` name `cloudposse/geodesic`, the company name is `cloudposse` and the stage name is `geodesic`
- The next place searched for resources is the directory with the same name as the "company". In our example, that would be `~/.geodesic/cloudposse`. Resources here would apply to all containers from the same company.
- The next place searched for resources is the directory with the same name as the "stage", which is generally the name of the project. In our example, that would be `~/.geodesic/geodesic`. Resources here would apply to all containers with the same base name, perhaps various forks of the same project.
- The final place searched is the directory with the full name of the Docker image: `$GEODESIC_CONFIG_HOME/$DOCKER_IMAGE`, 
i.e. `~/.geodesic/cloudposse/geodesic`. Files here are the most specific to this container. 

By loading them in this order, you can put your defaults at one level and then override/customize them at another, minimizing the amount of duplication needed to customize a wide range of containers. 

### Usage details
Preferences and Overrides are loaded in the order specified above and all that are found are loaded. 
For history files, only the last one found is used. To start keeping separate history, 
just create an empty history file in the appropriate place. 

While Preferences and Override files themselves must be `bash` scripts and will be directly loaded into 
the top-level Geodesic shell, they can of course call other programs. 
You can even use them to pull configurations out of other places.

Symbolic links must be relative if you want them to work both inside Geodesic and outside of it. 
Symbolic links that reference directories that are not below `$HOME` on the host will not work.

When possible, Geodesic mounts the host `$HOME` directory as `/localhost` and creates a symbolic link
from `$HOME` to `/localhost` so that files under `$HOME` on the host can be referenced by the 
exact same absolute path both on the host computer and inside Geodesic. For example, if the
host `$HOME` is `/Users/fred`, then `/Users/fred/src/example.sh` will refer to the same file both
on the host and from inside the Geodesic shell. 

In general, you should put most of your customization in the Preferences files. 
Geodesic (usually) takes care to respect and adapt to preferences set before it starts adding on top of them. 
The primary use for overrides is if you need the results of the initialization process as inputs to your configuration, 
or if you need to undo something Geodesic does not yet provide a configuration option for not doing in the first place. 

## WARNING
One of the key benefits of Geodesic is that it provides a consistent environment for all users regardless of their 
local machine. It eliminates the "it works on my machine" excuse. While these customization options can be great 
productivity enhancements as well as provide the opportunity to install new features to try them out before committing 
to installing them permanently, they can also create the kind of divergence in environments that brings back 
the "it works on my machine" problem. 

Therefore, we have included an option to disable the customization files: the preferences, the overrides, 
and the docker environment files. Simply set and export the host environment variable `$GEODESIC_CUSTOMIZATION_DISABLED` 
to any value other than "false" before launching Geodesic.

## TROUBLESHOOTING
If customizations are not being found or are not working as expected, 
you can set the host environment variable `$GEODESIC_TRACE` to "custom" before
launching Geodesic and a trace of the customization process will be output
to the console.

