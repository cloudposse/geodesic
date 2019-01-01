# Kubernetes Operations (kops)

Kops is one of the easiest ways to get a production grade Kubernetes cluster up and running. The `kops` command line tool (cli) is like `kubectl` for clusters. It handles all the standard CRUD operations necessary to manage the complete life cycle of a cluster.

It is possible to run any number of [kops clusters](http://github.com/kubernetes/kops) within an account. Our "best practice" is to define one cluster per project directory in the `/conf` folder. Then define a `.envrc` ([direnv](https://direnv.net/)) configuration per directory.
Any settings in this file will be automatically loaded when you `cd` in to the directory. Alternatively, they can be executed explicitly by running `direnv exec $directory $command`. This is useful when running commands as part of a CI/CD GitOps-style pipeline.

## Table of Contents

- [Kubernetes Operations (kops)](#kubernetes-operations-kops)
  - [Table of Contents](#table-of-contents)
  - [Features](#features)
  - [Configuration Settings](#configuration-settings)
  - [Provision a Kops Cluster](#provision-a-kops-cluster)
    - [Configure Environment Settings](#configure-environment-settings)
    - [Provision Dependencies](#provision-dependencies)
    - [Create the Cluster](#create-the-cluster)
  - [Operating the Cluster](#operating-the-cluster)
    - [Tips & Tricks](#tips--tricks)
    - [Upgrade a Cluster](#upgrade-a-cluster)
  - [References](#references)
  - [Getting Help](#getting-help)

## Features

- **Automated Provisioning** of Kubernetes clusters in [AWS](https://github.com/kubernetes/kops/blob/master/docs/aws.md) and [GCE](https://github.com/kubernetes/kops/blob/master/docs/tutorial/gce.md)
- **Highly Available (HA)** Kubernetes masters and nodes by using auto-scaling groups
- **Dry-runs & Idempotency** ensure predictable cluster operations
- **Kubernetes Addons** extend the default functionality [add-ons](https://github.com/kubernetes/kops/blob/master/docs/addons.md)
- **Command line Tool** supports all CRUD operations and has [autocompletion](https://github.com/kubernetes/kops/blob/master/docs/cli/kops_completion.md)
- **Declarative Manifests (YAML)** make GitOps style [Configuration](https://github.com/kubernetes/kops/blob/master/docs/manifests_and_customizing_via_api.md) easier
- [Templating](https://github.com/kubernetes/kops/blob/master/docs/cluster_template.md) and dry-run modes for creating manifests
- **Supports Multiple CNIs** providers [out of the box](https://github.com/kubernetes/kops/blob/master/docs/networking.md).
- **Lifecycle Hooks** make it easy to add containers and files to nodes via a [cluster manifest](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md)

## Configuration Settings

We create a [`kops`](https://github.com/kubernetes/kops) cluster from a manifest.

The default manifest go-template is located in [`/templates/kops/default.yaml`](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml)
and is compiled by running `build-kops-manifest`. We recommend adding this command as a build step in the [`Dockerfile`](Dockerfile) (e.g. `RUN build-kops-manifest`).

Most configuration settings are defined as environment variables. These can be set using the `.envrc` pattern.

<details>
<summary>List of Supported Environment Variables</summary>

| Environment Variable                               | Description of the setting                                                                     |
| -------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| BASTION_MACHINE_TYPE                               | AWS EC2 instance type of bastion host                                                          |
| KOPS_ADMISSION_CONTROL_ENABLED                     | Toggle if adminission controller should be enabled                                             |
| KOPS_API_LOAD_BALANCER_IDLE_TIMEOUT_SECONDS        | AWS ELB idle connection timeout for the API load balancer                                      |
| KOPS_AUTHORIZATION_RBAC_ENABLED                    | Toggle Kubernetes RBAC support                                                                 |
| KOPS_AVAILABILITY_ZONES                            | AWS Availability Zones (AZs) to use. Must all reside in the same region. Use an _odd_ number.  |
| KOPS_AWS_IAM_AUTHENTICATOR_ENABLED                 | Toggle IAM Authenticator support                                                               |
| KOPS_BASE_IMAGE                                    | AWS AMI base image for all EC2 instances                                                       |
| KOPS_BASTION_PUBLIC_NAME                           | Hostname that will be used for the bastion instance                                            |
| KOPS_CLOUDWATCH_DETAILED_MONITORING                | Toggle detailed CloudWatch monitoring (increases operating costs)                              |
| KOPS_CLUSTER_AUTOSCALER_ENABLED                    | Toggle the Kubernetes node autoscaler capability                                               |
| KOPS_CLUSTER_NAME                                  | Cluster base hostname (E.g. `${AWS_REGION}.${DNS_ZONE}`)                                       |
| KOPS_DNS_ZONE                                      | Authoritative DNS Zone that will be populated automatic with hostnames                         |
| KOPS_FEATURE_FLAGS                                 | Enable experimental features that not available by default                                     |
| KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE            | Ordered list of plug-ins to do authorization on secure port                                    |
| KOPS_KUBE_API_SERVER_AUTHORIZATION_RBAC_SUPER_USER | Username of the Kubernetes Super User                                                          |
| KOPS_MANIFEST                                      | The path to the manifest. Used by `build-kops-manifest`.                                       |
| KOPS_NETWORK_CIDR                                  | The network used by kubernetes for `Pods` and `Services` in the cluster                        |
| KOPS_NON_MASQUERADE_CIDR                           | A list of strings in CIDR notation that specify the non-masquerade ranges.                     |
| KOPS_PRIVATE_SUBNETS                               | Subnet CIDRs for all EC2 instances                                                             |
| KOPS_STATE_STORE                                   | S3 Bucket that will be used to store the cluster state (E.g. `s3://${AWS_REGION}.${DNS_ZONE}`) |
| KOPS_TEMPLATE                                      | Kops manifest go-template (gomplate) that descri                                               |
| KOPS_UTILITY_SUBNETS                               | Subnet CIDRs for the publically facing services (e.g. ingress ELBs)                            |
| KUBERNETES_VERSION                                 | Version of Kubernetes to deploy. Must be compatible with the `kops` release.                   |
| NODE_MACHINE_TYPE                                  | AWS EC2 instance type for the _default_ node pool                                              |
| NODE_MAX_SIZE                                      | Maximum number of EC2 instances in the _default_ node pool                                     |
| NODE_MIN_SIZE                                      | Minimum number of EC2 instances in the _default_ node pool                                     |

**IMPORTANT:**

1. `KOPS_NETWORK_CIDR` and `KOPS_NON_MASQUERADE_CIDR` **MUST NOT** overlap
2. `KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE` is a comma-separated list (e.g.`AlwaysAllow`,`AlwaysDeny`,`ABAC`,`Webhook`,`RBAC`,`Node`)
3. `KOPS_BASE_IMAGE` refers to one of the official AWS AMI's provided by `kops`. For more details, refer to the [official documentation](https://github.com/kubernetes/kops/blob/master/docs/images.md). Additionally, the [latest stable images](https://github.com/kubernetes/kops/blob/master/channels/stable) are published on their GitHub
4. `KOPS_FEATURE_FLAGS` are [published on their GitHub](https://github.com/kubernetes/kops/blob/master/docs/experimental.md)

</details>

## Provision a Kops Cluster

The process of provisioning a new `kops` cluster takes (3) steps. Here's what it looks like:

1. **Configure the environment settings**
   - Create a new project (e.g. `/conf/kops`) with an `.envrc`
   - Rebuild the `geodesic` image to generate a new `kops` manifest file. Then restart the shell
2. **Provision the `kops` dependencies using the [`terraform-aws-kops-state-backend`](https://github.com/cloudposse/terraform-aws-kops-state-backend) module with Terraform**
   - State backend (S3 bucket) that will store the YAML state
   - Cluster DNS zone that will be used by kops for service discovery
   - SSH key-pair to access the Kubernetes masters and nodes
3. **Execute the `kops create` on the manifest file to create the `kops` cluster**
   - Validate cluster is healthyo

We provide a reference example here in our [`terraform-root-modules/aws/kops`](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/kops) service catalog.

### Configure Environment Settings

Here is an example `.envrc`. Stick this in a project folder like `/conf/kops/` to enable kops support.

**NOTE:** For a full list of options, see the [Configuration Settings](#configuration-settings).

```bash
export KOPS_MANIFEST=/conf/kops/manifest.yaml
export KOPS_TEMPLATE=/templates/kops/default.yaml

export KOPS_CLUSTER_NAME=$(terraform output zone_name)
export KOPS_STATE_STORE=s3://$(terraform output bucket_name)
export KOPS_STATE_STORE_REGION=us-east-1
export KOPS_FEATURE_FLAGS=+DrainAndValidateRollingUpdate
export KOPS_BASE_IMAGE=kope.io/k8s-1.10-debian-jessie-amd64-hvm-ebs-2018-08-17

export KOPS_BASTION_PUBLIC_NAME="bastion"
export KOPS_PRIVATE_SUBNETS="172.20.32.0/19,172.20.64.0/19,172.20.96.0/19,172.20.128.0/19"
export KOPS_UTILITY_SUBNETS="172.20.0.0/22,172.20.4.0/22,172.20.8.0/22,172.20.12.0/22"
export KOPS_AVAILABILITY_ZONES="us-west-2a,us-west-2b,us-west-2c"

# Instance sizes
export BASTION_MACHINE_TYPE="t2.medium"
export MASTER_MACHINE_TYPE="t2.medium"
export NODE_MACHINE_TYPE="t2.medium"

# Min/Max number of nodes (aka workers)
export NODE_MAX_SIZE=2
export NODE_MIN_SIZE=2
```

**IMPORTANT** The `KOPS_CLUSTER_NAME=$(terraform output zone_name)` and `KOPS_STATE_STORE=s3://$(terraform output bucket_name)` settings must correspond to those provisioned by the `terraform-aws-kops-state-backend` module. 


After making any changes, rebuild the Docker image:

```bash
make docker/build
```

### Provision Dependencies

Run Terraform to provision the `kops` backend (S3 bucket, DNS zone, and SSH keypair):

```bash
make -C /conf/kops init apply
```

### Create the Cluster

Run the `geodesic` shell again and assume role to login to AWS:

```bash
assume-role
```

Change directory to `kops` folder:

```bash
cd /conf/kops
```

In this directory, there should be a `manifest.yaml` file which gets generated by running `build-kops-manifest` which renders [the template](https://github.com/cloudposse/geodesic/blob/master/rootfs/templates/kops/default.yaml) using your current environment settings. Typically, we add `RUN build-kops-manifest` as one of the last steps in the `Dockerfile`.

**NOTE**: you can override the `KOPS_TEMPLATE` to specify an alternative path to the manifest template file.

Run the following command to create the cluster. This will just initialize the cluster state, which involves writing writing a state file to the S3 bucket. It does not actually provision any AWS resources for the cluster.

```bash
kops create -f manifest.yaml
```

In AWS, it's required that all AWS EC2 instances have a master SSH key. Run the following command to add the SSH public key to the cluster:

```bash
kops create secret sshpublickey admin -i /secrets/tf/ssh/${NAMESPACE}-${STAGE}-kops-${AWS_REGION}.pub --name $KOPS_CLUSTER_NAME
```

Run the following command to provision the AWS resources for the cluster:

```bash
kops update cluster --yes
```

All done. The `kops` cluster is now up and running.

Run the following command to validate the cluster is healthy:

```bash
kops validate cluster
```

## Operating the Cluster

Use the `kubectl` command to interact with the Kubernetes cluster. To use the `kubectl` command (_e.g._ `kubectl get nodes`, `kubectl get pods`), you need to first export the `kubecfg` configuration settings from the cluster.

Run the following command to export `kubecfg` settings needed to connect to the cluster:

```bash
kops export kubecfg
```

**IMPORTANT:** You need to run this command every time you start a new shell and before you interact with the cluster (e.g. before running `kubectl`). By default, we set the `KUBECONFIG=/dev/shm/kubecfg` (shared memory based filesystem) so that it never touches disk and is wiped out when the shell exits.

See the documentation for [`kubecfg` settings for `kubectl`](https://github.com/kubernetes/kops/blob/master/docs/kubectl.md) for more details.

<details><summary>Show Example Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
⨠ kops validate cluster

Validating cluster us-west-2.example.company.co

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
bastions		Bastion	t2.medium	1	1	utility-${aws_region}a,utility-${aws_region}d,utility-${aws_region}c
master-${aws_region}a	Master	t2.medium	1	1	${aws_region}a
master-${aws_region}c	Master	t2.medium	1	1	${aws_region}c
master-${aws_region}d	Master	t2.medium	1	1	${aws_region}d
nodes			Node	t2.medium	2	2	${aws_region}a,${aws_region}d,${aws_region}c

NODE STATUS
NAME							                  ROLE	  READY
ip-172-20-108-58.${aws_region}.compute.internal	  node	  True
ip-172-20-125-166.${aws_region}.compute.internal  master  True
ip-172-20-62-206.${aws_region}.compute.internal	  master  True
ip-172-20-74-158.${aws_region}.compute.internal	  master  True
ip-172-20-88-143.${aws_region}.compute.internal	  node    True

Your cluster us-west-2.example.company.co is ready
```

</details>
<br>

Run the following command to list all nodes:

```bash
kubectl get nodes
```

<details><summary>Show Exaple Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
⨠ kubectl get nodes
NAME                                                STATUS   ROLES    AGE   VERSION
ip-172-20-108-58.${aws_region}.compute.internal    Ready    node     15m   v1.10.8
ip-172-20-125-166.${aws_region}.compute.internal   Ready    master   17m   v1.10.8
ip-172-20-62-206.${aws_region}.compute.internal    Ready    master   18m   v1.10.8
ip-172-20-74-158.${aws_region}.compute.internal    Ready    master   17m   v1.10.8
ip-172-20-88-143.${aws_region}.compute.internal    Ready    node     16m   v1.10.8
```

</details>
<br>

Run the following command to list all pods:

```bash
kubectl get pods --all-namespaces
```

<details><summary>Show Exapmle Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
⨠ kubectl get pods --all-namespaces
NAMESPACE     NAME                                                                        READY   STATUS    RESTARTS   AGE
kube-system   calico-kube-controllers-69c6bdf999-7sfdg                                    1/1     Running   0          1h
kube-system   calico-node-4qlj2                                                           2/2     Running   0          1h
kube-system   calico-node-668x9                                                           2/2     Running   0          1h
kube-system   calico-node-jddc9                                                           2/2     Running   0          1h
kube-system   calico-node-pszd8                                                           2/2     Running   0          1h
kube-system   calico-node-rqfbk                                                           2/2     Running   0          1h
kube-system   dns-controller-75b75f6f5d-tdg9s                                             1/1     Running   0          1h
kube-system   etcd-server-events-ip-172-20-125-166.${aws_region}.compute.internal         1/1     Running   0          1h
kube-system   etcd-server-events-ip-172-20-62-206.${aws_region}.compute.internal          1/1     Running   2          1h
kube-system   etcd-server-events-ip-172-20-74-158.${aws_region}.compute.internal          1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-125-166.${aws_region}.compute.internal                1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-62-206.${aws_region}.compute.internal                 1/1     Running   2          1h
kube-system   etcd-server-ip-172-20-74-158.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-125-166.${aws_region}.compute.internal             1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-62-206.${aws_region}.compute.internal              1/1     Running   3          1h
kube-system   kube-apiserver-ip-172-20-74-158.${aws_region}.compute.internal              1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-125-166.${aws_region}.compute.internal    1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-62-206.${aws_region}.compute.internal     1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-74-158.${aws_region}.compute.internal     1/1     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-kp2pp                                                   3/3     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-wg6gv                                                   3/3     Running   0          1h
kube-system   kube-dns-autoscaler-6874c546dd-tvbhq                                        1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-108-58.${aws_region}.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-125-166.${aws_region}.compute.internal                 1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-62-206.${aws_region}.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-74-158.${aws_region}.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-88-143.${aws_region}.compute.internal                  1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-125-166.${aws_region}.compute.internal             1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-62-206.${aws_region}.compute.internal              1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-74-158.${aws_region}.compute.internal              1/1     Running   0          1h
```

</details>
<br>
<br>

### Tips & Tricks

1. Use `kubens` to easily change your namespace context
2. Use `kubectx` to easily change between kubernetes cluster contexts
3. Use `kubeon` and `kubeoff` to enable the fancy kubernetes prompt

### Upgrade a Cluster

To upgrade the cluster or change settings (_e.g_. number of nodes, instance types, Kubernetes version, etc.):

1. Update the settings in the `.envrc` for the corresponding kops project
2. Rebuild Docker image (`make docker/build`)
3. Run `geodesic` shell (e.g. by running the wrapper script `example.company.co`)
   - assume role (`assume-role`) 
   - change directory to the `/conf/kops` folder (or which ever project folder contains your kops configurations)
4. Run `kops export kubecfg` to get the cluster context
5. Run `kops replace -f manifest.yaml` to replace the cluster resources (update state)
6. Run `kops update cluster` to view a plan of changes
7. Run `kops update cluster --yes` to apply pending changes
8. Run `kops rolling-update cluster` to view a plan of changes
9. Run `kops rolling-update cluster --yes --force` to force a rolling update (replace EC2 instances)

## References

- https://github.com/kubernetes/kops/blob/master/docs/manifests_and_customizing_via_api.md

## Getting Help

Did you get stuck? Find us on [slack](https://slack.cloudposse.com) in the `#geodesic` channel.
