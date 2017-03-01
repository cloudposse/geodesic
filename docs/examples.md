# Usage Examples

First, make sure you've followed the *Quickstart* up above.


## Available Commands

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


## Bringing up a cluster

```shell
cloud configure
cloud up
```

Now you'll want to edit the configuration files that were generated for the `kube-system` namespace.

```shell
cloud helm chart defaults init install
```

## Connecting to the cluster

```shell
cloud ssh
```

## Destroying a cluster

