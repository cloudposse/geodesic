---
title: DESIGN(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

design - Geodesic Design

### An Opinionated Framework

We designed this shell as the last layer of abstraction. It stitches all the tools together like `make`, `aws-cli`, `kops`, `helm`, `kubectl`, and `terraform`. As time progresses,
there will undoubtably be even more that come into play. For this reason, we chose to use a combination of `bash` and `make` which together are ideally suited to combine the 
strengths of all these wonderful tools into one powerful shell, without raising the barrier to entry too high.

The `cloud` command ties everything together. It's designed to call `make` targets within the various `module` directories. Targets are documented using `##` symbols preceding the target name. 

For example, calling `cloud kops ssh` works like this:

1. It checks to see if there's a module called `kops`. It finds one.
2. It checks to see if there's a nested module called `ssh`. It does not, so it calls the `ssh` target of the `kops` module.

Since we use `make` under-the-hood, you can add all your ENVs at the end of the command. Think of ENVs as named parameters. Alternatively, all environment variables can be passed as arguments. 

For the default environment variables, checkout `/etc/profile.d/defaults.sh`. We believe using ENVs this way is both consistent
with the "cloud" (12-factor) way of doing things, as well as a clear way of communicating what values are being passed without using a complicated convention. Additionally, you can set & forget these ENVs in your shell.

## LAYOUT

We leverage as many semantics of the linux shell as we can to make the experience as frictionless as possible.

* `/usr/local/include` houses all internal `Makefiles`. Any time `include something` is used in a `Makefile`, it will search this directory for `something`.
* `/etc/profile.d` is where shell profiles are stored (like aliases). These are executed when the shell starts.
* `/etc/bash_completion.d` is where all bash completion scripts are kept and sourced when the shell starts.
* `/usr/local/bin` has some helper scripts
* `/etc/motd` is the current "Message of the Day"
* `/localhost` is where we house the local state (like your temporary AWS credentials). This is mounted to your `HOME` directory.
* `/conf` is where all configurations belong. For example, stick your terraform module invocations in this directory. When using `terraform`, the directory names are mapped directly to a bucket prefix for terraform state which include subdirectories (e.g. `/conf/us-west-2/vpc` will map to a state folder prefix of `us-west-2/vpc`).

## EXTENDING

Geodesic was written to be easily extended. There are a couple ways to do it. 

You can easily extend the Geodesic shell by creating your own repo with a `Dockerfile`. We suggest you have it inherit `FROM geodeisc:latest` (or pin it to a [build number](https://travis-ci.org/cloudposse/geodesic) for stability). If you want to add or modify core functionality, this is the recommended way to do it.

In side your container, you can replace any of our code with your own to make it behave exactly as you wish. You could even create one dedicated shell per cluster with logic tailored specifically for that cluster.

### Here are some other tips.

1. Many of our `Makefiles` do an `-include Makefile.*`, which means, we'll include other `Makefiles` in that directory. To add additional functionality, simply drop-in your `Makefile.something` in that directory.

2. Want to add additional aliases or affect the shell? Drop your script in `/etc/profile.d` and it will be loaded automatically when the shell starts. 

3. Need to set some environment variables? Use an `.envrc` in the corresponding directory

As you can see, you can easily change almost any aspect of how the shell works simply by extending it.


