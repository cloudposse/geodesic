## Developing Terraform Modules

This document is not actually about Terraform or how to write good Terraform code or how
to manage the transition from Terraform version 0.11 to 0.12. This document is about the 
recommended workflow and division of responsibility to use when creating and deploying
new Terraform code.

### The 3 tiers of Terraform code in the Geodesic architecture

Under Geodesic, we use 3 tiers of code in the process of deploying Terraform resources.

#### 1. The Terraform Module

We start with what Terraform calls a [Terraform Module](https://www.terraform.io/docs/glossary.html#module),
which they define as "a self-contained collection of Terraform configurations that manages a collection of related 
infrastructure resources." Each module is intended to provision a set of resources that constitute
a single logical "thing". For example, a database, which could include AWS instances to run the 
database software, EBS volumes to store the data, Security Groups and IAM roles and policies to 
limit network access to the database, etc.

The idea of a single module is to do one thing, do it well, and make it easy for users
to customize by changing inputs, while at the same time making it easy to use by providing
as many reasonable defaults as possible.

Each Terraform module is placed in its own GitHub repository. CloudPosse has published
[dozens](https://github.com/cloudposse?utf8=✓&q=terraform&type=&language=) and you can
follow those examples or use your own pattern. CloudPosse maintains a repo called
[build-harness](https://github.com/cloudposse/build-harness) which contains tools for,
among other things, creating README.md and other documentation files from a combination
of `yaml` files and the code itself. This process is not well documented and will likely
undergo revision as we transition to Terraform 0.12, so for now your best bet is to simply
start with an existing module and make changes to the code to suit your needs. 
[terraform-aws-key-pair](https://github.com/cloudposse/terraform-aws-key-pair) is a reasonable module to use
as a starting point, though there are many others that may already be closer to what you want
to accomplish.

In particular, copy the Makefile and README.yaml files, which will then let you generate 
documentation by executing:
```bash
make init
make readme/deps
make readme
```
You may need to run that from inside a Geodesic container if you do not want to install
some of the necessary support (such as the Go language runtime) on your workstation. 

Of course, you will want to modify your README.yaml extensively.

We recommend you break down your Terraform module into 3 files:

1. `variables.tf` contains all the inputs to the module, with defaults if possible. All the 
information from `variables.tf` including descriptions will be included in the generated 
documentation.
1. `output.tf` contains all the outputs from the module. Again, all the information will
be included in the documentation.
1. `main.tf` conatins all the logic and other "code" that implements the module.

#### 2. The Terraform "Root Module"

We consider each root module to be a "project" that gets some component installed. It uses
one or more Terraform modules plus its own additional inputs and logic to create a 
possibly more complicated component that a single module should handle. Also, while the Terraform modules should do
one thing, and be fairly generic about how they do it, allowing users to customize it as needed, 
the Terraform Root Module is the place where opinions are imposed and decisions get made. For 
example, a module should get all its inputs via variables, but a Root Module may decide to get
its inputs from Environment variables or AWS SSM Parameter Store parameters or somewhere else.

Each Terraform root module is stored inside its own directory in the shared Terraform
root module Git repository. CloudPosse's public repo is 
[cloudposse/terraform-root-modules](https://github.com/cloudposse/terraform-root-modules) and
each company should also have thier own private repo for any variations that the public repo
does not support.


#### 3. The project folder inside Geodesic

Each account/environment should have its own, customized Geodesic container, made 
from its own GitHub repository. In that container,
under `/conf` are directories, one per "project". Generally that means one for all the `helmfiles`,
one for `kops` (which has both Terraform and `kops` artifacts), and one for each Terraform
root module to install. 

In the repo for the envoronment's Geodesic, create a directory under `/conf` for 
your Terraform root module. Copy the `.envrc`, `Makefile.tasks`, and `terraform.envrc` files 
from `/conf/kops` into the new directory. The `.envrc` and `Makefile.tasks` files are boilerplate
and do not need to be changed. 

Edit the `terraform.envrc` file so that the `TF_CLI_INIT_FROM_MODULE` points to your 
Terraform root module. Be sure to pin it to a specific version.

If needed (and it usually is), add a `terraform.tfvars` file, in which you set the vaules
of all the inputs to your Terraform root module that need to be set (i.e. that do not 
have acceptable defaults).

Once that is done, build, install, and run the Geodesic Docker container.

### The local development workflow

In general, the project folder sets a `TF_CLI_INIT_FROM_MODULE` (via `terraform.envrc`)
that refers to a remote Terraform Root Module via a GitHub URL,
and the Root Module also refers to Terraform Modules via their GitHub URLs. To develop
locally, you clone these repos onto your local machine and make modifications there, 
and temporarily replace the GitHub URLs with path names on your local workstation
that point to the directories where your development versions of these modules reside. 
As a convenience, Geodesic mounts your home directory into the Geodesic container and
creates a symbolic link so that you can reach your home directory using the same
absolute path inside Geodesic that you would use on your workstation. This means
that as long as you do your development in directories under your home directory
(and on the same disk device), your workstation's absolute paths to your development 
files will work inside Geodesic just as well as outside it. 

#### Example

Let us say you want to install a group of `widgets` via Terraform. We would break that 
down into 3 pieces, as explained above:

1. A GitHub repo called `terraform-widget` which contains a module that provisions 
a widget and any necessary supporting resources that all widgets would need.
1. A directory in the `terraform-root-module` repo called `widgets` that provisions
the set of widgets in the way that your environments want to have them.
1. A directory in each environment's Geodesic Docker container, under `/conf`, that
sets the details specific to that environment and then invokees the `widgets` root 
module.

Let us also say you are develping on a Mac computer and your `$HOME`
directory is `/Users/user`. To ease development, you want to organize all the code you are
modifying in some kind of directory structure under `$HOME`, so that it is all
available both inside and outside the Geodesic shell.
 
You might create a subdirectory `src` for all your development
work, and under that have directories for each repo, `terraform-widget`, `terraform-root-modules`
and one for your Geodesic, something like `prod.cpco.io`.

```
WORKSTATION:

$HOME=/Users/user

/Users/usr/src
            |- terraform-widget/
            |- terraform-root-modules/aws/widgets/
            |- prod.cpco.io/conf/widgets/
```

Then, in `prod.cpco.io/conf/widgets/` you would set 
```
export TF_CLI_INIT_FROM_MODULE=/Users/usr/src/terraform-root-modules/aws/widgets
```
and in 
```hcl
module "widget" {
  source         = "/Users/usr/src/terraform-widget"
  ...
}
```

You can then use Terraform commands like `init`, `plan`, and `apply` as usual, and they will
refer to your local source. Keep in mind that `make init` and `terraform init` copy the
remote code into the local directory for later use, so if you make external changes,
you need to run `make reset` to clean out the old code and `make init` to bring in the new code.
