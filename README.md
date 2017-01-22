# Geodesic

*definition:* relating to or denoting the shortest possible line between two points on a sphere or other curved surface.

The geodesic shell is the fastest way to get up and running with a rock solid cloud platform. 
It takes an opinionated approach to cloud architecture, which therefore allows many assumptions on how it works to be made. 

## Quickstart

Install the geodesic client, if you haven't already:
```
curl https://geodesic.sh | bash
```

Run the geodesic shell:
```
geodesic
```

Configure your AWS credentials in `/geodesic/state/aws`

Run `assume-role $role` where $role is the one you configured in your AWS configuration.

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

```
cloud config checkout demo.dev.cloudposse.com CLUSTER_STATE_BUCKET_REGION=us-west-2
```


## Layout Inside of the Geodesic Shell

* `/geodesic/modules` houses all `Makefiles` 
* `/etc/profile.d` is where shell profiles are stored (like aliases)
* `/usr/local/bin` has some helper scripts
* `/etc/motd` is the current "Message of the Day"

## Extending the Geodesic Shell

You can easily extend the Geodesic shell by creating your own repo with a `Dockerfile`. We suggest you have it inherit `FROM geodeisc:latest` or some specific build.
In side your container, you can replace any of our code with your own to make it behave exactly as you wish. 

## Usage Examples

### Bringing up a cluster

```
cloud configure
cloud up
cloud init
```

### Connecting to the cluster
```
cloud ssh
```

### Destroying a cluster
```
cloud down
```

### Pulling down an existing cluster
```
cloud config checkout config.demo.dev.cloudposse.com
```

### Save your current cloud configuration state
Note: 
* if multiple people are administering the same cluster, we suggest you coordinate before push changes. 
* We use a simple optimistic locking approach that involves a `serial` file stored on S3. If your serial matches the upstream, we presume nothing has changed and allow you to push your files. If not, you'll need to manually reconcile what has changed.

```
cloud config push
```


### Using `kubectl` outside of geodesic

Have `kubectl installed on your local machine? Then after setting up `geodesic`, you can export the `KUBECONFIG` environment variable to point to the one in `geodesic`. Note, `kubectl` does not support `~` in for the `HOME` directory.
```
export KUBECONFIG="${HOME}/.geodesic/kubernetes/kubeconfig" 
```
