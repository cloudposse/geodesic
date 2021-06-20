---
title: DESIGN(1) | Geodesic
author:
- Erik Osterman
date: June 2021
---

## NAME

design - Geodesic Design

### An Opinionated Framework

We designed this shell as the last layer of abstraction. It stitches all the tools together like `make`, `aws-cli`, `kops`, `helm`, `kubectl`, and `terraform`. As time progresses,
there will undoubtedly be even more that come into play. For this reason, we chose to use a combination of `bash` and `make` which together are ideally suited to combine the 
strengths of all these wonderful tools into one powerful shell, without raising the barrier to entry too high.

The `cloud` command ties everything together. It's designed to call `make` targets within the various `module` directories. Targets are documented using `##` symbols preceding the target name. 

For example, calling `cloud kops ssh` works like this:

1. It checks to see if there's a module called `kops`. It finds one.
2. It checks to see if there's a nested module called `ssh`. It does not, so it calls the `ssh` target of the `kops` module.

Since we use `make` under-the-hood, you can add all your ENVs at the end of the command. Think of ENVs as named parameters. Alternatively, all environment variables can be passed as arguments. 

For the default environment variables, checkout `/etc/profile.d/defaults.sh`. We believe using ENVs this way is both consistent
with the "cloud" (12-factor) way of doing things, as well as a clear way of communicating what values are being passed without using a complicated convention. Additionally, you can set & forget these ENVs in your shell.

## LAYOUT

We leverage as many semantics of the Linux shell as possible to make the experience as frictionless as possible.

* `/usr/local/include` houses all internal `Makefiles`. Any time `include something` is used in a `Makefile`, it will search this directory for `something`.
* `/etc/profile.d` is where shell profiles are stored (like aliases). These are executed when the shell starts.
* `/etc/bash_completion.d` is where all bash completion scripts are kept and sourced when the shell starts.
* `/usr/local/bin` has some helper scripts.
* `/etc/motd` is the current "Message of the Day".
* `/localhost` is where we retrieve configuration (such as AWS profiles) from the Host file system and save the local state (like your temporary AWS credentials). This is mounted to your `$HOME` directory, and inside Geodesic a symbolic link is created from the Host's `$HOME` to `/localhost` so that scripts on the Host that reference absolute paths under the Host's `$HOME` directory will continue to work. (Note, however, that `$HOME` inside Geodesic is not the same as `$HOME` on the Host. `bash` scripts meant to work both on the host and inside Geodesic should reference `${LOCAL_HOME:-$HOME}` instead.) Linux users take note of [ownership of files created on the host from inside Geodesic](https://github.com/cloudposse/geodesic/issues/594).
* `/conf` _(deprecated)_ is where pre-[Atmos](https://github.com/cloudposse/atmos) configurations belong. For example, stick your Terraform module invocations in this directory. When using `terraform` with `direnv`, the directory names are mapped directly to a bucket prefix for Terraform state which includes subdirectories (e.g. `/conf/us-west-2/vpc` will map to a state folder prefix of `us-west-2/vpc`), unless you set `TF_BUCKET_PREFIX_FORMAT=basename-pwd`, in which case the bucket name will just be the directory name, (`vpc` in our example).
* `/components` is where configuration-as-code such as Terraform and Helmfiles belong when using [Atmos](https://github.com/cloudposse/atmos).
* `/stacks` is where [Atmos](https://github.com/cloudposse/atmos) YAML configuration files (primarily variable settings for `/components`) belong.

## EXTENDING

Geodesic was written to be easily extended. There are a couple of ways to do it. 

You can easily extend the Geodesic shell by creating your own `Dockerfile`. We suggest you have it inherit `FROM geodeisc:latest-<base-OS>`, where `<base-OS>` is one of our supported base operating systems, currently `alpine` (phasing out) or `debian` (recommended), or pin it to a [Docker tag](https://hub.docker.com/r/cloudposse/geodesic/tags?page=1&ordering=last_updated) of the form `<Geodesic-release-version>-<base-OS>` for greater stability. (Geodesic release versions can, of course, be found [here](https://github.com/cloudposse/geodesic/releases).) If you want to add or modify core functionality, this is the recommended way to do it.

Inside your container, you can replace any of our code with your own to make it behave exactly as you wish. You could even create one dedicated shell per cluster with logic tailored specifically for that cluster.

### Here are some other tips.

1. Many of our `Makefiles` do an `-include Makefile.*`, which means, we'll include other `Makefiles` in that directory. To add additional functionality, simply add a `Makefile.something` file in that directory.

2. Want to add additional aliases or affect the shell? Drop your script in `/etc/profile.d`, and it will be loaded automatically when the shell starts. 

3. Need to set some environment variables? Use an `.envrc` in the corresponding directory

As you can see, you can easily change almost any aspect of how the shell works simply by extending it.
