
# Geodesic [![Build Status](https://travis-ci.org/cloudposse/geodesic.svg?branch=master)](https://travis-ci.org/cloudposse/geodesic)

## Introduction

Geodesic is the fastest way to get up and running with a rock solid, production grade cloud platform. 

It provides a fully customizable framework for defining and building world-class cloud infrastructures backed by AWS (https://aws.amazon.com/) and powered by kubernetes (https://kubernetes.io/). It couples best-of-breed technologies with engineering best-practices to equip organizations with the tooling that enables clusters to be spun up in record time without compromising security.

Geodesic is composed of two parts:

1. It is an interactive command-line shell. The shell includes the *ultimate* mashup of cloud orchestration tools. Those tools are then integrated to work in concert with each other using a consistent framework. Installation of the shell is as easy as running a docker container.  
2. It is a distribution of essential services. The distribution includes a collection of Helm charts for CI/CD, VPN, SSH Bastion, Automatic DNS, Automatic TLS,  Automatic Monitoring, Account Management, Log Collection, Load Balancing/Routing, Image Serving, and much more. What makes these charts even more valuable is that they were designed from the ground up work well with each other and integrate with external services for authentication (SSO/OAuth2, MFA).

An organization may chose to leverage all of these components, or just the parts the make their life easier.

> *definition:* relating to or denoting the shortest possible line between two points on a sphere or other curved surface.

## Badges of Honor

[![Docker Stars](https://img.shields.io/docker/stars/cloudposse/geodesic.svg)](https://hub.docker.com/r/cloudposse/geodesic)
[![Docker Pulls](https://img.shields.io/docker/pulls/cloudposse/geodesic.svg)](https://hub.docker.com/r/cloudposse/geodesic)
[![GitHub Stars](https://img.shields.io/github/stars/cloudposse/geodesic.svg)](https://github.com/cloudposse/geodesic/stargazers) 
[![GitHub Issues](https://img.shields.io/github/issues/cloudposse/geodesic.svg)](https://github.com/cloudposse/geodesic/issues)
[![Average time to resolve an issue](http://isitmaintained.com/badge/resolution/cloudposse/geodesic.svg)](http://isitmaintained.com/project/cloudposse/geodesic "Average time to resolve an issue")
[![Percentage of issues still open](http://isitmaintained.com/badge/open/cloudposse/geodesic.svg)](http://isitmaintained.com/project/cloudposse/geodesic "Percentage of issues still open")
[![Contributions Welcome](https://img.shields.io/badge/contributions-welcome-brightgreen.svg)](https://github.com/cloudposse/geodesic/pulls)
[![License](https://img.shields.io/badge/license-APACHE%202.0%20-brightgreen.svg)](https://github.com/cloudposse/geodesic/blob/master/LICENSE)


## Help

**Got a question?** 

File a GitHub [issue](https://github.com/cloudposse/geodesic/issues), send us an [email](mailto:hello@cloudposse.com) or reach out to us on [Gitter](https://gitter.im/cloudposse/).

## Features
* **Secure** - TLS/PKI, OAuth2, MFA Everywhere, remote access VPN, [ultra secure bastion/jumphost](https://github.com/cloudposse/bastion) with audit capabilities and slack notifications, [IAM assumed roles](https://github.com/cloudposse/aws-assume-role/), automatic key rotation, encryption at rest, and VPCs;
* **Repeatable** - 100% Infrastructure-as-Code with change automation and support for scriptable admin tasks in any language, including terraform;
* **Extensible** - A framework where everything can be be extended to work the way you want to to;
* **Comprehensive** - our [helm charts library](https://github.com/cloudposse/charts) are designed to tightly integrate your cloud-platform with Github Teams and Slack Notifications and CI/CD systems like TravisCI, CircleCI or Jenkins;
* **OpenSource** - Permissive [APACHE 2.0](LICENSE) license means no lock-in and no on-going license fees

Geodesic is is exactly what you need for a secure, turnkey cloud platform that packages everything a typical startup or technology organization needs to get up and running in record time without compromising security or preventing customization.

## Technologies

Geodesic is a framework for provisioning cloud infrastructure and the applications that sit on top of it. We leverage as many existing tools as possible to facilitate cloud fabrication and administration. We're like the connective tissue that sits between all of the components of a modern cloud.

* [`kops`](https://github.com/kubernetes/kops/) for kubernetes cluster orchestration 
* [`aws-cli`](https://github.com/aws/aws-cli/) for interacting directly with the AWS APIs
* [`helm`](https://github.com/kubernetes/helm/) for installing packages like varnish or apache on the kubernetes cluster
* [`terraform`](https://github.com/hashicorp/terraform/) for provisioning miscellaneous resources on pretty much any cloud
* [`kubectl`](https://kubernetes.io/docs/user-guide/kubectl-overview/) for controlling kubernetes resources like deployments or load balancers
* [`s3fs`](https://github.com/s3fs-fuse/s3fs-fuse) for mounting encrypted S3 buckets that store cluster configurations and secrets
* [`hub`](https://github.com/github/hub) for managing your infrastructure-as-code on Github - the way you can extend geodesic to do pretty much anything you want


## Prerequisites

### Install Docker

Docker can be easily installed by following the instructions for your OS:

* [Linux](https://docs.docker.com/linux/step_one/); alternatively, if you're comfortable on the command-line, run  `curl -fsSL https://get.docker.com/ | sh` 
* [Windows](https://docs.docker.com/windows/step_one/)
* [Mac OS](https://docs.docker.com/mac/step_one/)


## Quick Start

1. Install the geodesic client, if you haven't already: (feel free to inspect the shell script!)
```
curl -s https://geodesic.sh | bash
```

2. Run the geodesic shell:
```
geodesic
```

3. Configure your AWS credentials by running `setup-role`

4. Run `assume-role $role` where $role is the one you configured in your AWS configuration.

5. Run `cloud configure`

6. Run `cloud up`

All done. Your cloud is now up and running.


## Usage Examples

First, make sure you've followed the *Quickstart* up above.


### Show Available Commands

```shell
$ cloud help

Available targets:

  deps                                Setup environment
  init                                Initialize cluster
  create                              Create a new cluster
  up                                  Bring up a new cluster
  down                                Tear down an existing cluster
  ssh                                 Connect to the cluster via SSH
  config                              Manage configuration
  bootstrap                           Bootstrap the overall system
  kops                                Toolbox for kops
  kubernetes                          Toolbox for kubernetes
  helm                                Toolbox for helm
  hub                                 Toolbox for github repo
  terraform                           Toolbox for terraform
  help                                This help screen
```


### Bringing up a cluster

```shell
cloud configure
cloud up
```

Now you'll want to edit the configuration files that were generated for the `kube-system` namespace.

```shell
cloud helm chart defaults init install
```

### Connecting to the cluster

```shell
cloud ssh
```

### Destroying a cluster

```shell
cloud down
```


## FAQ

### Cannot list directory

```
$ ls /s3
ls: reading directory '.': I/O error
```

This means your AWS credentials have expired. Re-run `assume-role`.

### Cannot unmount folder
```bash
$ cloud config unmount
umount: can't unmount /s3: Resource busy
```

This means some process (maybe you) is in the directory. Try running `cd /` and rerun the unmount.

### Caveats

* While the underlying tools support multiple cloud providers, we are currently only testing with AWS. Pull Requests welcome.
* Geodesic is tested on Linux and OSX. If you use Windows, we'd be a happy to work with you to get it working there as well


## Extending the Geodesic Shell

Geodesic was written to be easily extended. There are a couple ways to do it. 

You can easily extend the Geodesic shell by creating your own repo with a `Dockerfile`. We suggest you have it inherit `FROM geodeisc:latest` (or pin it to a [build number](https://travis-ci.org/cloudposse/geodesic) for stability). If you want to add or modify core functionality, this is the recommended way to do it.

In side your container, you can replace any of our code with your own to make it behave exactly as you wish. You could even create one dedicated shell per cluster with 
logic tailored specifically for that cluster.

Here are some other tips. Most of our modules do an `-include Makefile.*`, which means, we'll include other `Makefiles` in that directory. To add additional functionality,
simply drop-in your `Makefile.something` in that module directory.

Want to add additional aliases or affect the shell? Drop your script in `/etc/profile.d` and it will be loaded automatically when the shell starts. 

As you can see, you can easily change almost any aspect of how the shell works simply by extending it.



## Layout Inside of the Geodesic Shell

We leverage as many semantics of the linux shell as we can to make the experience as frictionless as possible.

* `/usr/local/include` houses all internal `Makefiles`. Any time `include something` is used in a `Makefile`, it will search this directory for `something`.
* `/etc/profile.d` is where shell profiles are stored (like aliases). These are executed when the shell starts.
* `/etc/bash_completion.d` is where all bash completion scripts are kept and sourced when the shell starts.
* `/usr/local/bin` has some helper scripts
* `/etc/motd` is the current "Message of the Day"
* `/mnt/local` is where we house the local state (like your temporary AWS credentials)
* `/mnt/remote` is where we mount the S3 bucket for cluster state; these files are never written to disk and only kept in memory for security

## Design Decisions

We designed this shell as the last layer of abstraction. It stitches all the tools together like `make`, `aws-cli`, `kops`, `helm`, `kubectl`, and `terraform`. As time progresses,
there will undoubtably be even more that come into play. For this reason, we chose to use a combination of `bash` and `make` which together are ideally suited to combine the 
strengths of all these wonderful tools into one powerful shell, without raising the barrier to entry too high.

The `cloud` command ties everything together. It's designed to call `make` targets within the various `module` directories. Targets are documented using `##` symbols preceding the target name. 

For example, calling `cloud kops ssh` works like this:

1. It checks to see if there's a module called `kops`. It finds one.
2. It checks to see if there's a nested module called `ssh`. It does not, so it calls the `ssh` target of the `kops` module.

Since we use `make` under-the-hood, you can add all your ENVs at the end of the command. Think of ENVs as named parameters. Alternatively, all environment variables can be passed as arguments. For example, running `cloud ssh SSH_USERNAME=admin` is identical to running `cloud ssh --ssh-username=admin`.

For the default environment variables, checkout `/etc/profile.d/defaults.sh`. We believe using ENVs this way is both consistent
with the "cloud" (12-factor) way of doing things, as well as a clear way of communicating what values are being passed without using a complicated convention. Additionally, you can set & forget these ENVs in your shell.

```shell
cloud config use demo.example.org CLUSTER_STATE_BUCKET_REGION=us-west-2
```


## Contributing

#### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/bastion/issues) to report any bugs or file feature requests.

#### Developing

PRs are welcome. In general, we follow the "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull request** so that we can review your changes

NOTE: Be sure to merge the latest from "upstream" before making a pull request!

## Change Log

View our closed [Pull Requests](https://github.com/cloudposse/geodesic/pulls?q=is%3Apr+is%3Aclosed).


## License

Apache2 © [Cloud Posse, LLC](https://cloudposse.com)

## About

Geodesic is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know at <hello@cloudposse.com>

We love [Open Source Software](https://github.com/cloudposse/)! 

See [our other projects][community]
or [hire us][hire] to help build your next cloud-platform.

  [website]: http://cloudposse.com/
  [community]: https://github.com/cloudposse/
  [hire]: http://cloudposse.com/contact/
  
### Contributors

[![Erik Osterman](http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144)](https://osterman.com/) 

[Erik Osterman](https://github.com/osterman) 
	
[![Igor Rodionov](http://s.gravatar.com/avatar/bc70834d32ed4517568a1feb0b9be7e2?s=144)](https://sindresorhus.com) 

[Igor Rodionov](https://github.com/goruha) 


