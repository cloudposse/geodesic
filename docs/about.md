## Features

* **Secure** - TLS/PKI, OAuth2, MFA Everywhere, remote access VPN, [ultra secure bastion/jumphost](https://github.com/cloudposse/bastion) with audit capabilities and slack notifications, [IAM assumed roles](https://github.com/99designs/aws-vault/), automatic key rotation, encryption at rest, and VPCs
* **Repeatable** - 100% Infrastructure-as-Code with change automation and support for scriptable admin tasks in any language, including Terraform
* **Extensible** - A framework where everything can be extended to work the way you want to
* **Comprehensive** - our [helm charts library](https://github.com/cloudposse/charts) are designed to tightly integrate your cloud-platform with Github Teams and Slack Notifications and CI/CD systems like TravisCI, CircleCI or Jenkins
* **OpenSource** - Permissive [APACHE 2.0](LICENSE) license means no lock-in and no on-going license fees

## Technologies

At its core, Geodesic is a framework for provisioning cloud infrastructure and the applications that sit on top of it. We leverage as many existing tools as possible to facilitate cloud fabrication and administration. We're like the connective tissue that sits between all of the components of a modern cloud.

* [`atlantis`](https://www.runatlantis.io/) - GitOps style operations by Pull Request. Ideal for terraform, helm and helmfile.
* [`aws-vault`](https://github.com/99designs/aws-vault) for securely storing and accessing AWS credentials in an encrypted vault for the purpose of assuming IAM roles
* [`aws-cli`](https://github.com/aws/aws-cli/) for interacting directly with the AWS APIs
* [`chamber`](https://github.com/segmentio/chamber) for managing secrets with AWS SSM+KMS and exposing them as environment variables
* [`helm`](https://github.com/kubernetes/helm/) for installing packages like Varnish or Apache on the Kubernetes cluster
* [`helmfile`](https://github.com/roboll/helmfile) for 12-factorizing chart values and installing chart collections
* [`kops`](https://github.com/kubernetes/kops/) for Kubernetes cluster orchestration
* [`kubectl`](https://kubernetes.io/docs/user-guide/kubectl-overview/) for controlling kubernetes resources like deployments or load balancers
* [`gcloud`, `gsutil`](https://cloud.google.com/sdk/) for integration with Google Cloud (e.g. GKE, GCE, Google Storage)
* [`gomplate`](https://github.com/hairyhenderson/gomplate/) for template rendering configuration files using the GoLang template engine. Supports lots of local and remote datasources
* [`goofys`](https://github.com/kahing/goofys/) a high-performance Amazon S3 file system for mounting encrypted S3 buckets that store cluster configurations and secrets
* [`terraform`](https://github.com/hashicorp/terraform/) for provisioning miscellaneous resources on pretty much any cloud

[](https://media.giphy.com/media/26FmS6BRnPVPo2FDq/source.gif)

## Documentation

Extensive documentation is provided on our [Documentation Hub](https://docs.cloudposse.com/geodesic). 
