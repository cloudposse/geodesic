---
title: KOPS(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

kops - (Deprecated) Kubernetes Operations (kops)

## SYNOPSIS 

***Deprecation notice*** CloudPosse no longer supports `kops` for managing Kubernetes clusters.
This document is retained for historical reference, but should not be used for new clusters.
Some binaries, such as `kops` itself, used to be shipped pre-installed in Geodesic, and
some, such as `direnv` and `tfenv` had special support as well. Some of these are no 
longer installed, and some may not work as advertised due to bit rot.

***Historical synopsis***
Kops is one of the easiest ways to get a production grade Kubernetes cluster up and running. The `kops` command line tool (cli) is like `kubectl` for clusters. It handles all the standard CRUD operations necessary to manage the complete life cycle of a cluster.

It is possible to run any number of [kops clusters](http://github.com/kubernetes/kops) within an account. Our 
current practice is to define one cluster per Geodesic contianer, with all cluster configuration
in the `/conf` folder. We are planning to publish guidelines for how to manage multiple clusters per container, 
but that is still a work in progress that will introduce some new patterns.

## DESCRIPTION

- This document describes how to set up a single `kops` cluster in a single Geodesic container.
- The described usage pattern corresponds to [Geodesic](https://github.com/cloudposse/geodesic) version 0.95.1,
[Reference Architecture](https://github.com/cloudposse/reference-architectures) version 0.7.0, and
[terraform-root-modules](https://github.com/cloudposse/terraform-root-modules) version 0.71.0
- Check the versions! Geodesic, `kops`, Kubernetes, and other tools referenced in this documentation are 
constantly evolving, and it is likely this documentation will be at least slightly out-of-date within days
of its publication. Also, because it is only updated manually (rather than generated automatically), there will likely 
be times when one part of this document intends to reference one version of a resource while another part references 
a different version. Please keep these facts in mind when you are using this document to help you set up your own cluster.

## FEATURES

- **Automated Provisioning** of Kubernetes clusters in [AWS](https://github.com/kubernetes/kops/blob/master/docs/aws.md) and [GCE](https://github.com/kubernetes/kops/blob/master/docs/tutorial/gce.md)
- **Highly Available (HA)** Kubernetes masters and nodes by using auto-scaling groups
- **Dry-runs & Idempotency** ensure predictable cluster operations
- **Kubernetes Addons** extend the default functionality [add-ons](https://github.com/kubernetes/kops/blob/master/docs/addons.md)
- **Command line Tool** supports all CRUD operations and has [autocompletion](https://github.com/kubernetes/kops/blob/master/docs/cli/kops_completion.md)
- **Declarative Manifests (YAML)** make GitOps style [Configuration](https://github.com/kubernetes/kops/blob/master/docs/manifests_and_customizing_via_api.md) easier
- [Templating](https://github.com/kubernetes/kops/blob/master/docs/cluster_template.md) and dry-run modes for creating manifests
- **Supports Multiple CNIs** providers [out of the box](https://github.com/kubernetes/kops/blob/master/docs/networking.md).
- **Lifecycle Hooks** make it easy to add containers and files to nodes via a [cluster manifest](https://github.com/kubernetes/kops/blob/master/docs/cluster_spec.md)

## OVERVIEW

The process of provisioning a new `kops` cluster takes (3) steps. Here's what it looks like:

1. **Configure the parameter settings**
   - Create a new project (e.g. `/conf/kops`). 
   - Configure parameters in multiple places.
   - Rebuild the `geodesic` image. Then restart the shell.
2. **Provision the `kops` dependencies using the [`kops`](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/kops) terraform root module**
   - State backend (S3 bucket) that will store the YAML state.
   - Cluster DNS zone that will be used by kops for service discovery.
   - SSH key-pair to access the Kubernetes masters and nodes.
   - Write settings to SSM Parameter Store.
3. **Execute the `kops create` on the manifest file to create the `kops` cluster**
   - Build the manifest.
   - Validate the cluster is healthy.


### Configuration Settings Overview

We use 2 different mechanisms for storing configuration parameters.

1. Parameters can be stored in files. This is best for parameters that are not secret, should be under source code 
control, and do not need to be shared among "projects." Most parameters should be stored in files.
1. Parameters can be saved in and read from AWS SSM Parameter Store using [Chamber](https://github.com/segmentio/chamber)
 or the [Terraform](https://www.terraform.io/) `aws_ssm_parameter` resource. This is best for secrets, as they are protected via AWS IAM, and do
 not risk being checked into source code control. We also use this for parameters that are automatically generated 
 or are used by more than
 one project, such as `KOPS_NETOWRK_CIDR`. However access to SSM is severely rate limited, so parameters that 
 are accessed frequently should be stored somewhere else. For the sake of brevity, we sometimes refer to the AWS SSM Parameter Store 
 as just "SSM".

WARNING: Do not define the same parameter in _both_ SSM and `.envrc` files, as this can lead to confusing behavior as 
the two definitions compete for precedence.

SSM parameters are grouped by "prefix" and access to them can be controlled with IAM policies on a per-prefix basis. 
`chamber` calls the prefix a "service". For `kops` configuration we use the prefix/service "kops" for 
parameters stored in SSM. This means an environment variable named `FOO` (all uppercase) would be set via `chamber write kops foo <value>`
or `aws ssm put-parameter --name '/kops/foo --value <value>` (SSM parameter keys used by the tools are all lowercase).

To facilitate setting configurations via files, and to keep configurations segregated, we create (inside the `/conf` 
folder) a folder per "project". Roughly speaking, a "project" is a Terraform module or other group of DevOps scripts
and configurations that form a self-contained unit (though possibly with dependencies on other projects).


#### `direnv`

We use [direnv](https://direnv.net/) to automatically load configurations into enviornment variables
when you `cd` into a directory. Alternatively, they can be executed explicitly by running 
`direnv exec $directory $command`. This is useful when running commands as part of a CI/CD GitOps-style pipeline.

The way `direnv` works is that when you `cd` into a directory, it looks for a file named `.envrc` and if it
finds it, reads and executes the contents of the file. It generally expects to find `bash` style environment
variable assignments of the form
```bash
export NAME=vaule
```
Any environment variables set in the `.envrc` file are exported into the current environment, and, critically,
removed from the environment when you `cd` out of the directory. 

Normally `direnv` only reads the `.envrc` file, but CloudPosse adds a `use envrc` command to the file, which
causes `direenv` to read all the files in the directory that have `.envrc` extensions. This allows parameters
to be set automatically by `direnv` without requiring that the settings be put in a hidden file.

##### `/conf/.envrc`

In the `/conf` directory itself, we put a file named `.envrc` which contains just this one line:
```
export MAKE_INCLUDES="Makefile Makefile.*"
```
That supports our general pattern of installing a `Makefile.tasks` file in each Terraform project directory, which 
in turn downloads a `Makefile` specific to that Terraform module. 

#### `/conf/kops/`

We create a "project" folder for the `kops` configuration. Inside this goes a few different configurations files.

##### `.envrc`

Every project files gets a `.envrc` file that is automatically loaded by `direnv`. Because this is a hidden
file, we only put in this file the `direnv` commands needed to load and process other configuration files.
Currently, our `.envrc` file contains these commands:
- [`use envrc`](https://github.com/cloudposse/geodesic/blob/0.95.1/rootfs/etc/direnv/rc.d/envrc) tells direnv to load all the files in the directory that have names ending with .envrc
- [`use terraform`](https://github.com/cloudposse/geodesic/blob/0.95.1/rootfs/etc/direnv/rc.d/terraform) maps certain
environment variables to ones that will get passed to Terraform
- [`use atlantis`](https://github.com/cloudposse/geodesic/blob/0.95.1/rootfs/etc/direnv/rc.d/atlantis) maps certain
`atlantis` [environment variables](https://www.runatlantis.io/docs/atlantis-yaml-reference.html#reference) to ones
that will get passed to Terraform
- [`use tfenv`](https://github.com/cloudposse/geodesic/blob/0.95.1/rootfs/etc/direnv/rc.d/tfenv) maps environment
variables to `terraform` command-line flags.

##### `kops.envrc`, `terraform.envrc`

We finish configuring the environment by placing commands like `export ENVVAR=value` in files whose names
end with `.envrc`. We name the files and group the commands by component. So in `/conf/kops` we place 
`kops.envrc` which gets environment variables needed by `kops` directly (and not stored in SSM) and
`terraform.envrc` which gets environment variables needed by `terraform`.

##### `terraform.tfvars`

We also create a `terraform.tfvars` file which holds `terraform` configuration data in the form of assignments to 
`terraform` variables. For historical reasons, some `kops` parameters are actually configured in `terraform.tfvars`,
then `terraform` uses this information to create more parameters, which it then stores in SSM. 

### Terraform and Chamber

We use Terraform to provision resources such as domain names and AWS S3 buckets. For `kops` we also use 
it to generate several configuration parameters which Terraform then stores in SSM. However, most tools
that we use cannot read parameters out of SSM, so we use Chamber to read _all_ the parameters out of SSM
and place them in environment variables, which all our tools can use. 

### Where Did That Value Come From?

Because of the interactions between Docker, Chamber, `direnv`, and Terraform, it can be difficult to determine 
where the final value of a parameter originated. This document focuses on the recommended place to set 
parameters, but you can dig into some details of alternate possiblities here:
<details>
<summary>Show details</summary>
To illustrate the situation, here is an example tracing how
the environment variable `KOPS_PRIVATE_SUBNETS` is set and used:

1. `KOPS_PRIVATE_SUBNETS` could first be set in Geodesic's Dockerfile
1. We recommend that you do not run Geodesic directly, but rather create a customized Docker container based
on a specific version of Geodesic. So `KOPS_PRIVATE_SUBNETS` could be set in your customized Dockerfile. While 
we do not recommend setting `KOPS_PRIVATE_SUBNETS` there, we do recommend setting other parameters there.
1. One of the first things you do inside Geodesic is `assume-role`. While this is only concerned with 
AWS credentials, it does set `AWS_REGION` and `AWS_DEFAULT_REGION`, and also sets `TF_VAR_aws_assume_role_arn` 
which is used by Terraform as the default value for the Terraform variable `aws_assume_role_arn`
1. Then you `cd /conf/kops` and `direnv` loads all the `.envrc` files and populates the environment, so if you 
have `KOPS_PRIVATE_SUBNETS` set in `kops.envrc` (which, because we later set it in SSM, you should not),
then that value is now what is set.
1. Note that `direnv`, through our custom additions of `use terraform` and `use tfenv`, will pass [some of the 
environment variables](../rootfs/etc/direnv/rc.d/terraform) to `terraform` as command line arguments and will pass all 
of the environment variables as default values for `terraform` variables. 
1. Then you `make deps` and `terraform apply`. The Terraform module reads the value of `network_cidr` from 
`terraform.tfvars`, computes subnet CIDRs bocks, and stores the value in SSM with the key `/kops/kops_private_subnets`. 
1. You run `make kops/shell` to load all the values stored in SSM under the `/kops` prefix into your local environment
by executing `chamber exec kops -- bash -l`. At this point, 
the value that Terraform just generated overwrites `KOPS_PRIVATE_SUBNETS` and this is the value going forward.
1. Except, as noted above, if you have also set `KOPS_PRIVATE_SUBNETS` in `kops.envrc`, then if you `cd /conf`,
`direnv` will set `KOPS_PRIVATE_SUBNETS` to the value it had before you did `cd /conf/kops` in step 4, which is the value
from one of the Dockerfiles. And then if you `cd /conf/kops` again, `direnv` will overwrite the value from 
SSM with the value from `kops.envrc`. This is why you should not set a parameter in both a file and SSM.

</details>

### Create the cluster

The following describes how to create a cluster, treating the setting of parameters in various places as 
steps in the creation process.

- Note: Our standard configuration of `kops` isolates the cluster in private subnets (not directly accessible from the 
public internet) of a VPC (a configuration commonly called a "Private Cluster"), with the VPC created and managed by 
`kops`, and this is what is described here. We have recently added support for deploying a cluster inside a VPC that 
is not created or managed by `kops` but created some other way, which we call a "shared VPC". The adjustments needed 
to operate in a shared VPC are described below under [Shared VPC](#shared-vpc).
        
### Setting the Parameters

#### Dockerfile

The Geodesic Dockerfile provides some default values for enviornment variables, but for most of them
it is no longer recommended to rely on them and they may be removed in future versions. (The few we recommend you 
continue to get from Geodesic are indicated in the table below with a "Suggested Value" of `<inherit>`.)
However, we consider it reasonable, if not necessarily
"best", practice for you to define these environment variables in the Dockerfile you use to build your custom
Geodesic container. Note that if you generated your Dockerfile using our [Reference Architecture tools](https://github.com/cloudposse/reference-architectures#get-started), then 
these will already be set for you.

<details>
<summary>Used by `kops` and other tools</summary>

| Environment Variable                               | Description of the Parameter                 | Suggested Value | 
| -------------------------------------------------- | -------------------------------------------|------------------|
| NAMESPACE | A short string that distinguishes your organization for others, such as "cpco" | _(must be custom)_ |
| STAGE | A short string that indicates an environment with a organization | One of: audit, corp, data, dev, prod, root, staging | 
| AWS_DEFAULT_PROFILE | The name of the profile in your `~/.aws/config` to use when executing AWS commands | `"${NAMESPACE}-${STAGE}-admin"` |
| AWS_REGION | The AWS Region to use for AWS commands. Use a region geographically close to you. | `us-west-2` |
</details>
<details>
<summary>Specific to `kops`</summary>

| Environment Variable                               | Description of the Parameter                 | Suggested Value | 
| -------------------------------------------------- | -------------------------------------------|------------------|
| KOPS_MANIFEST | Location of the (generated) `kops` manifest file | `<inherit>` |
| KUBECONFIG | Where to store/find "kubeconfig" file used by `kubectl` | `<inherit>`
| KUBECONFIG_TEMPLATE | Template file for `build-kubeconfig` to use to create a "kubeconfig" file | `<inherit>` |
| KOPS_BASTION_PUBLIC_NAME | The hostname part of the Bastion server's domain name | bastion |
</details>


#### `/conf/kops/terraform.envrc`, `/conf/kops/terraform.tfvars` 

Geodesic uses Terraform to set up networking and DNS, computing values that will be used later. 

The `/conf/kops/terraform.envrc` file normally only contains 2 parameters:

| `terraform.envrc` Variable | Description of the Parameter                 | Suggested Value |
|--------------------|----------------------------------------------|-----------------|
| TF_CLI_INIT_FROM_MODULE | The URL for the `kops` "Terraform root module" | _see below_ |
| TF_CLI_PLAN_PARALLELISM | The maximum number of concurrent operations as Terraform walks the graph. | 2 |

- `TF_CLI_INIT_FROM_MODULE` should be a version-pinned reference to the `kops` module of the 
CloudPosse [Terraform Root Modules repo](https://github.com/cloudposse/terraform-root-modules). For this
version of the documentation, it should be `git::https://github.com/cloudposse/terraform-root-modules.git//aws/kops?ref=tags/0.71.0`,
which should match the "terraform-root-modules" version stated above under [Usage](#usage).


The remaining
parameters should be configured in `/conf/kops/terraform.tfvars`. If you generated your Dockerfile using our 
[Reference Architecture tools](https://github.com/cloudposse/reference-architectures#get-started), then 
all these values will already be set for you.

<details>
<summary>Terraform Variables</summary>

| Terraform Variable | Description of the Parameter                 | Suggested Value |
|--------------------|----------------------------------------------|-----------------|
| network_cidr | The CIDR network block to use for the cluster | _see below_ |
| kops_non_masquerade_cidr | The CIDR network block to use for communication inside the cluster | `100.64.0.0/10` |
| zone_name | The DNS name of the DNS Zone in which to place the cluster | _see below_ |
| region | The AWS region where the cluster should be created. | Should be the same as `$AWS_REGION` |

##### Notes: 
- Our reference architecture expects there to be a "parent domain", typically a second-level domain name such as `cpco.io`, 
  that all services for the entire organization are under. The `zone_name` is the domain for all services in this
  specific account, and we recommend `${STAGE}.<parent domain>`.
- The `kops` cluster will be named `${AWS_REGION}.${ZONE_NAME}`. Unfortunately, CloudPosse documentation and tools
  are inconsistent in their use of `zone_name` and `dns_zone` because their usage has evolved over the years, and 
  some tools enforce the convention that the cluster
  name is `${AWS_REGION}.${ZONE_NAME}`, while others have a variable called `dns_zone` but in fact require it to be
  set to the full cluster name. Please use extra care when you encounter these variable names elsewhere.
- If you are using a [Shared VPC](#shared-vpc), you should leave `network_cidr` unset and add `create_vpc = "false"`
- There are additional parameters that can be set, but usually the defaults are good. For full details, 
  see the [source files](https://github.com/cloudposse/terraform-root-modules/blob/master/aws/kops/variables.tf).
</details>

#### `/conf/kops/kops.envrc`

We create a [`kops`](https://github.com/kubernetes/kops) cluster from a manifest. We create the manifest
by combining environment variables with a template, which is itself selected by an environment variable.
The following environment variables can be set in `/conf/kops/kops.envrc`. None are required, but for stability
you should at a minimum set the following variables.


| Critical Environment Variables  | Description of the Parameter                                                                     | Recommended value |
| ------------------------------- | ---------------------------------------------------------------------------------------------- |-------------------|
| KOPS_TEMPLATE                   | Location of kops manifest go-template (gomplate) that describes the cluster, may be a URL | _see below_ |
| KUBERNETES_VERSION              | Version of Kubernetes to install                                                          | 1.11.9 |
| KOPS_BASE_IMAGE                 | The AWS [AMI to use](https://github.com/kubernetes/kops/blob/master/docs/images.md) when creating EC2 instances. | _see below_ |
| KOPS_AUTHORIZATION_RBAC_ENABLED | Set to "true" to enable [Kubernetes RBAC](https://kubernetes.io/blog/2017/10/using-rbac-generally-available-18/) (strongly recommended) | true |
| BASTION_MACHINE_TYPE | AWS Instance type for the Bastion server | t3.small |
| MASTER_MACHINE_TYPE | AWS Instance type for the Kubernetes master nodes | t3.medium |
| NODE_MACHINE_TYPE | AWS Instance type for the Kubernetes worker nodes | t3.medium |
| NODE_MAX_SIZE                                      | Maximum number of EC2 instances in the _default_ node pool   | 2                                  |
| NODE_MIN_SIZE                                      | Minimum number of EC2 instances in the _default_ node pool      | 2                               |

- Notes:
1. `KOPS_TEMPLATE` used to point to a file in the local file system by default, but we now recommend using a URL
pointing to a specific version of the template published in our [Reference Architecture GitHub](https://github.com/cloudposse/reference-architectures). 
Be sure to use the "raw text" URL from GitHub, not the HTML URL. At the time of this writing, the recommended value for `KOPS_TEMPLATE` is 
 `https://raw.githubusercontent.com/cloudposse/reference-architectures/0.7.0/templates/kops/kops-private-topology.yaml.gotmpl`
1. `KOPS_BASE_IMAGE` refers to one of the official AWS AMI's provided by `kops`. 
For more details, refer to the [official documentation](https://github.com/kubernetes/kops/blob/master/docs/images.md). 
Additionally, the [latest stable images](https://github.com/kubernetes/kops/blob/master/channels/stable) are published 
on their GitHub. At the time of this writing, the recommended value of `KOPS_BASE_IMAGE` is
`kope.io/k8s-1.11-debian-jessie-amd64-hvm-ebs-2018-08-17`

There are some other environment variables you can set in `/conf/kops/kops.envrc` but the defaults are usually sufficient.
<details>
<summary>Other Environment Variables</summary>

| Environment Variable                               | Description of the setting                                          |
| -------------------------------------------------- | ------------------------------------------------------------------- |
| KOPS_API_LOAD_BALANCER_IDLE_TIMEOUT_SECONDS        | AWS ELB idle connection timeout for the API load balancer           | 
| KOPS_AWS_IAM_AUTHENTICATOR_ENABLED                 | Toggle IAM Authenticator support                                    |
| KOPS_BASTION_PUBLIC_NAME                           | Hostname that will be used for the bastion instance                 |
| KOPS_CLOUDWATCH_DETAILED_MONITORING                | Toggle detailed CloudWatch monitoring (increases operating costs)   |
| KOPS_CLUSTER_AUTOSCALER_ENABLED                    | Toggle the Kubernetes node autoscaler capability                    |
| KOPS_FEATURE_FLAGS                                 | Enable experimental features that are not available by default      |
| KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE            | Ordered list of plug-ins to do authorization on secure port         |

**IMPORTANT:**

1. `KOPS_KUBE_API_SERVER_AUTHORIZATION_MODE` is a comma-separated list (e.g.`AlwaysAllow,AlwaysDeny,ABAC,Webhook,RBAC,Node`)
4. `KOPS_FEATURE_FLAGS` are [published on their GitHub](https://github.com/kubernetes/kops/blob/master/docs/experimental.md)

</details>

#### Terraform generated configuration

In addition to creating AWS resources, Terraform generates the following parameters that it stores in SSM (using
lowercase names) and which then can be exported into the shell environment as environment variables using Chamber.
It is best that you do NOT configure these manually, but if you do need to change the values, you need to
change them in SSM **after** using Terraform to generate your AWS resources, and be aware that if `terraform`
is run again, it will overwrite the values you set.

<details>
<summary>Parameters Generated by Terraform</summary>

| SSM/Environment Variable                               | Description of the Parameter               |
| -------------------------------------------------- | -------------------------------------------|
| KOPS_CLUSTER_NAME | The cluster name used by `kops` |
| KOPS_STATE_STORE | The name of the S3 bucket where `kops` stores its state files |
| KOPS_STATE_STORE_REGION | The AWS region where `kops` stores its state files |
| KOPS_DNS_ZONE | the Route53 hosted zone in which `kops` will create DNS records |
| KOPS_NETWORK_CIDR | CIDR block of the kops virtual network | 
| KOPS_PRIVATE_SUBNETS | CIDR blocks of the kops private subnets |
| KOPS_UTILITY_SUBNETS | CIDR block of the kops utility (public) subnets |
| KOPS_NON_MASQUERADE_CIDR | The CIDR block for pod IPs |
| KOPS_AVAILABILITY_ZONES | The AWS Availability Zones in which the cluster will be provisioned |
</details>

### Shared VPC

Normally, `kops` creates and manages its own VPC. However, you may want to create a shared VPC that `kops` will
not modify, in order to more easily add other services to it. We provide a [VPC](https://github.com/cloudposse/terraform-root-modules/tree/master/aws/vpc)
Terraform module that creates a VPC and stores in SSM the information `kops` needs in order to use it. Details
instructions on how to use that module are beyond the scope of this document, but briefly, you can just use
it following the same pattern used for other "Terraform root modules". The key configuration items are:
- Remove `network_cidr` from `/conf/kops/terraform.tfvars` and copy its value to `vpc_cidr_block` in 
`/conf/vpc/terraform.tfvars`
- Set `create_vpc = "false"` in `/conf/kops/terraform.tfvars`

Be sure to create the VPC first, before provisioning anything relating to `kops`

### Provisioning Resources

Now that you have all the configuration set, build your custom Geodesic container, start it, and go through the following
steps from within the container.

- `assume-role` to assume an IAM role with appropriate permissions
- `cd /conf/kops` not only changes your working directory, but causes `direnv` to set up your environment variables
- `make deps` loads Terraform modules, configures Terraform state storage, and downloads a Makefile for the next steps
- `terraform apply` (type "yes" when prompted) creates S3 bucket, DNS zone, and SSH keypair for use by `kops`

At this point, there are new settings (generated by Terraform), and you need to take steps to load them into your
shell environment. 
- `make kops/shell` puts you into a subshell with the new settings loaded into your environment

From here forward you need to make sure you are continuing to operate from within this subshell. When the Geodesic 
command line prompt is 2 lines, a `+` at the end of the first line lets you know that the `kops` parameters are loaded.

- `make kops/build-manifest` creates the `$KOPS_MANIFEST` file
- `make kops/create` loads the manifest into `kops`
- `make kops/create-secret-sshpublickey` loads the SSH key into `kops` (for communicating with the EC2 instances)
- `make kops/apply` actually creates the cluster

The cluster make take 5-10 minutes to fully come on line. 
- `kops validate cluster` or `make kops/validate` to check on the status of the cluster. Once it has validated,
your cluster is up and running and ready to use.


## Operating the Cluster

Use the `kubectl` command to interact with the Kubernetes cluster. To use the `kubectl` command 
(_e.g._ `kubectl get nodes`, `kubectl get pods`), you need to first export the `kubecfg` configuration settings 
from the cluster.

Run the following command to export `kubecfg` settings needed to connect to the cluster:

```bash
kops export kubecfg
```

**IMPORTANT:** You need to run this command every time you start a new shell and before you interact with the cluster 
(e.g. before running `kubectl`). By default, we set the `KUBECONFIG=/dev/shm/kubecfg` (shared memory based filesystem) 
so that it never touches disk and is wiped out when the shell exits. Also, before you run `kops export kubecfg` you
need to have run `assume-role` and `make kops/shell`, in order to have the necessary credentials available for
`kops` to be able to generate the `kubecfg`.

See the documentation for [`kubecfg` settings for `kubectl`](https://github.com/kubernetes/kops/blob/master/docs/kubectl.md) 
for more details.

<details><summary>Show Example Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
⨠ kops validate cluster

Validating cluster us-west-2.example.company.co

INSTANCE GROUPS
NAME			ROLE	MACHINETYPE	MIN	MAX	SUBNETS
bastions		Bastion	t2.medium	1	1	utility-us-west-2a,utility-us-west-2d,utility-us-west-2c
master-us-west-2a	Master	t2.medium	1	1	us-west-2a
master-us-west-2c	Master	t2.medium	1	1	us-west-2c
master-us-west-2d	Master	t2.medium	1	1	us-west-2d
nodes			Node	t2.medium	2	2	us-west-2a,us-west-2d,us-west-2c

NODE STATUS
NAME							                  ROLE	  READY
ip-172-20-108-58.us-west-2.compute.internal	  node	  True
ip-172-20-125-166.us-west-2.compute.internal  master  True
ip-172-20-62-206.us-west-2.compute.internal	  master  True
ip-172-20-74-158.us-west-2.compute.internal	  master  True
ip-172-20-88-143.us-west-2.compute.internal	  node    True

Your cluster us-west-2.example.company.co is ready
```

</details>
<br>

Run the following command to list all nodes:

```bash
kubectl get nodes
```

<details><summary>Show Example Output</summary>

Below is an example of what it should _roughly_ look like (IPs and Availability Zones may differ).

```
⨠ kubectl get nodes
NAME                                                STATUS   ROLES    AGE   VERSION
ip-172-20-108-58.us-west-2.compute.internal    Ready    node     15m   v1.11.9
ip-172-20-125-166.us-west-2.compute.internal   Ready    master   17m   v1.11.9
ip-172-20-62-206.us-west-2.compute.internal    Ready    master   18m   v1.11.9
ip-172-20-74-158.us-west-2.compute.internal    Ready    master   17m   v1.11.9
ip-172-20-88-143.us-west-2.compute.internal    Ready    node     16m   v1.11.9
```

</details>
<br>

Run the following command to list all pods:

```bash
kubectl get pods --all-namespaces
```

<details><summary>Show Example Output</summary>

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
kube-system   etcd-server-events-ip-172-20-125-166.us-west-2.compute.internal         1/1     Running   0          1h
kube-system   etcd-server-events-ip-172-20-62-206.us-west-2.compute.internal          1/1     Running   2          1h
kube-system   etcd-server-events-ip-172-20-74-158.us-west-2.compute.internal          1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-125-166.us-west-2.compute.internal                1/1     Running   0          1h
kube-system   etcd-server-ip-172-20-62-206.us-west-2.compute.internal                 1/1     Running   2          1h
kube-system   etcd-server-ip-172-20-74-158.us-west-2.compute.internal                 1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-125-166.us-west-2.compute.internal             1/1     Running   0          1h
kube-system   kube-apiserver-ip-172-20-62-206.us-west-2.compute.internal              1/1     Running   3          1h
kube-system   kube-apiserver-ip-172-20-74-158.us-west-2.compute.internal              1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-125-166.us-west-2.compute.internal    1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-62-206.us-west-2.compute.internal     1/1     Running   0          1h
kube-system   kube-controller-manager-ip-172-20-74-158.us-west-2.compute.internal     1/1     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-kp2pp                                                   3/3     Running   0          1h
kube-system   kube-dns-5fbcb4d67b-wg6gv                                                   3/3     Running   0          1h
kube-system   kube-dns-autoscaler-6874c546dd-tvbhq                                        1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-108-58.us-west-2.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-125-166.us-west-2.compute.internal                 1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-62-206.us-west-2.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-74-158.us-west-2.compute.internal                  1/1     Running   0          1h
kube-system   kube-proxy-ip-172-20-88-143.us-west-2.compute.internal                  1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-125-166.us-west-2.compute.internal             1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-62-206.us-west-2.compute.internal              1/1     Running   0          1h
kube-system   kube-scheduler-ip-172-20-74-158.us-west-2.compute.internal              1/1     Running   0          1h
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

1. Update the settings in the `.envrc` files for the corresponding kops project
2. Rebuild Docker image (`make docker/build`)
3. Run `geodesic` shell (e.g. by running the wrapper script `example.company.co`)
   - assume role (`assume-role`) 
   - change directory to the `/conf/kops` folder (or whichever project folder contains your kops configurations)
   - `make kops/shell`
4. Run `kops export kubecfg` to get the cluster context
1. Run `make kops/build-manifest` to create a new `manifest.yaml`
5. Run `kops replace -f manifest.yaml` to replace the cluster resources (update state)
6. Run `kops update cluster` to view a plan of changes
7. Run `kops update cluster --yes` to apply pending changes
8. Run `kops rolling-update cluster` to view a plan of changes
9. Run `kops rolling-update cluster --yes --force` to force a rolling update (replace EC2 instances)

## REFERENCES

- https://github.com/kubernetes/kops/blob/master/docs/manifests_and_customizing_via_api.md

## GETTING HELP

Did you get stuck? Find us on [slack](https://slack.cloudposse.com) in the `#geodesic` channel.
