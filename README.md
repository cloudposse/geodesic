# Geodesic

*definition:* relating to or denoting the shortest possible line between two points on a sphere or other curved surface.

The geodesic shell is the fastest way to get up and running with a rock solid cloud platform. 

It takes an opinionated approach to cloud architecture, which therefore allows many assumptions to be made on how it works. 

The end result is a highly consistent, turnkey cloud platform that follows best practices while at the same time packs almost everything a typical 
startup needs to get up and running in record time.  

Since we run in `docker`, the barrier to entry is very low. Users don't need to download & configure all of the dependencies. Just install docker, and run the installer to get up and going. 

## Technologies

This shell bundles multiple tools to facilitate cloud adminstration.

* `kops` for kubernetes cluster orchestration
* `aws-cli` for interacting directly with the AWS APIs
* `helm` for installing packages on the kubernetes cluster
* `terraform` for provisioning miscellaneous resources 
* `kubectl` for controlling kubernetes

NOTE: we currently only support running the docker shell on Linux and OSX. If you use Windows, we'd be a happy to work with you to get it working there as well.

## Caveats

* While the underlying tools support multiple cloud providers, we are currently only testing with AWS. Pull Requests welcome.

## Prerequisites

### Install Docker

Docker can be easily installed by following the instructions for your OS:

* [Linux](https://docs.docker.com/linux/step_one/), you can run  `curl -fsSL https://get.docker.com/ | sh` on your command line and everything is done automatically (if you have `curl` installed, which is normally the case),
* [Windows](https://docs.docker.com/windows/step_one/)
* [Mac OS](https://docs.docker.com/mac/step_one/)

## Quickstart

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

## Usage Examples

First, make sure you've followed the *Quickstart* up above.

### Bringing up a cluster

```shell
cloud configure
cloud up
cloud init
```

### Connecting to the cluster

```shell
cloud ssh
```

### Destroying a cluster

```shell
cloud down
```shell

### Pulling down an existing cluster

```shell
cloud config checkout config.demo.dev.cloudposse.com
```

### Save your current cloud configuration state
Note: 
* if multiple people are administering the same cluster, we suggest you coordinate before push changes. 
* We use a simple optimistic locking approach that involves a `serial` file stored on S3. If your serial matches the upstream, we presume nothing has changed and allow you to push your files. If not, you'll need to manually reconcile what has changed.

```shell
cloud config push
```


### Using `kubectl` outside of geodesic

Do you have `kubectl` installed on your local machine? Then after setting up `geodesic`, you can export the `KUBECONFIG` environment variable to point to the one in `geodesic`. Note, `kubectl` does not support `~` in for the `HOME` directory.

```shell
export KUBECONFIG="${HOME}/.geodesic/kubernetes/kubeconfig" 
```

## Design Decisions

We designed this shell as the last layer of abstraction. It stitches all the tools together like `aws-cli`, `kops`, `helm`, `kubectl`, and `terraform`. As time progresses,
there will undoubtably be even more that come into play. For this reason, we chose to use a combination of `bash` and `make` which together are ideally suited to combine the 
strengths of all these wonderful tools into one powerful shell.

The `cloud` command ties everything together. It's designed to call `make` targets within the various `module` directories. Targets are documented using `##` symbols preceding the target name. 

For example, calling `cloud distro kube-system list-available` works like this:

1. It checks to see if there's a module called `distro`. It finds one.
2. It checks to see if there's a nested module called `kube-system`. If finds one.
3. It checks to see if there's a module called `list-available`. It does not, so it calls the `list-available` target of that module.

Since we use `make`, you can add all your ENVs at the end of the command. Think of ENVs as named parameters. 

For example, we can pass `CLUSTER_STATE_BUCKET_REGION` to affect where the S3 bucket is pulled from. We believe using ENVs this way is both consistent
with the "cloud" way of doing this as well as a clear way of communicating what values are being passed. Additionally, you can set & forget these ENVs in your shell.

```shell
cloud config checkout demo.dev.cloudposse.com CLUSTER_STATE_BUCKET_REGION=us-west-2
```


## Layout Inside of the Geodesic Shell

* `/geodesic/modules` houses all `Makefiles` 
* `/etc/profile.d` is where shell profiles are stored (like aliases)
* `/usr/local/bin` has some helper scripts
* `/etc/motd` is the current "Message of the Day"

## Extending the Geodesic Shell

You can easily extend the Geodesic shell by creating your own repo with a `Dockerfile`. We suggest you have it inherit `FROM geodeisc:latest` or some specific build.
In side your container, you can replace any of our code with your own to make it behave exactly as you wish. You could even create one dedicated shell per cluster with 
logic tailored specifically for that cluster.

Here are some other tips. Most of our modules do an `-include Makefile.*`, which means, we'll include other `Makefiles` in that directory. To add additional functionality,
simply drop-in your `Makefile.something` in that module directory.

Want to add additional aliases or affect the shell? Drop your script in `/etc/profile.d` and it will be loaded automatically when the shell starts. 

As you can see, you can easily change almost any aspect of how the shell works simply by extending it.


