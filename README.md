# Geodesic [![Build Status](https://github.com/cloudposse/geodesic/workflows/docker/badge.svg)](https://github.com/cloudposse/geodesic/actions?query=workflow%3Adocker) [![FOSSA Status](https://app.fossa.io/api/projects/git%2Bgithub.com%2Fcloudposse%2Fgeodesic.svg?type=shield)](https://app.fossa.io/projects/git%2Bgithub.com%2Fcloudposse%2Fgeodesic?ref=badge_shield) [![Latest Release](https://img.shields.io/github/release/cloudposse/geodesic.svg)](https://github.com/cloudposse/geodesic/releases/latest) [![Slack Community](https://slack.cloudposse.com/badge.svg)](https://slack.cloudposse.com) [![Slack Archive](https://img.shields.io/badge/slack-archive-blue.svg)](https://archive.sweetops.com/geodesic)

[![README Header][readme_header_img]][readme_header_link]

[![Cloud Posse][logo]](https://cpco.io/homepage)

<!--




  ** DO NOT EDIT THIS FILE
  **
  ** This file was automatically generated by the `build-harness`.
  ** 1) Make all changes to `README.yaml`
  ** 2) Run `make init` (you only need to do this once)
  ** 3) Run`make readme` to rebuild this file.
  **
  ** (We maintain HUNDREDS of open source projects. This is how we maintain our sanity.)
  **





-->

![Geodesic](docs/geodesic-small.png)

Geodesic is the fastest way to get up and running with a rock solid, production grade cloud platform built entirely from Open Source technologies. 

It’s a swiss army knife for creating and building consistent platforms to be shared across a team environment.

It easily versions staging environments in a repeatable manner that can be followed by any team member.

It's a way of doing things that allows companies to collaborate on infrastructure (~snowflakes~) and radically reduce Total Cost of Ownership, along with a vibrant and active [slack community](https://slack.cloudposse.com).

It provides a fully customizable framework for defining and building cloud infrastructures backed by [AWS](https://aws.amazon.com/) and powered by [kubernetes](https://kubernetes.io/). It couples best-of-breed technologies with engineering best-practices to equip organizations with the tooling that enables clusters to be spun up in record time without compromising security. 

It's works natively with Mac OSX, Linux, and [Windows 10 (WSL)](https://docs.microsoft.com/en-us/windows/wsl/install-win10).


---

This project is part of our comprehensive ["SweetOps"](https://cpco.io/sweetops) approach towards DevOps.
[<img align="right" title="Share via Email" src="https://docs.cloudposse.com/images/ionicons/ios-email-outline-2.0.1-16x16-999999.svg"/>][share_email]
[<img align="right" title="Share on Google+" src="https://docs.cloudposse.com/images/ionicons/social-googleplus-outline-2.0.1-16x16-999999.svg" />][share_googleplus]
[<img align="right" title="Share on Facebook" src="https://docs.cloudposse.com/images/ionicons/social-facebook-outline-2.0.1-16x16-999999.svg" />][share_facebook]
[<img align="right" title="Share on Reddit" src="https://docs.cloudposse.com/images/ionicons/social-reddit-outline-2.0.1-16x16-999999.svg" />][share_reddit]
[<img align="right" title="Share on LinkedIn" src="https://docs.cloudposse.com/images/ionicons/social-linkedin-outline-2.0.1-16x16-999999.svg" />][share_linkedin]
[<img align="right" title="Share on Twitter" src="https://docs.cloudposse.com/images/ionicons/social-twitter-outline-2.0.1-16x16-999999.svg" />][share_twitter]




It's 100% Open Source and licensed under the [APACHE2](LICENSE).











## Screenshots


![Demo](https://sweetops.com/wp-content/uploads/2019/03/termtosvg_fmnxoium.svg)
*<br/>[Example of running a shell](https://github.com/cloudposse/testing.cloudposse.co) based on the `cloudposse/geodesic` base docker image.*


## Introduction

These days, the typical software application is distributed as a docker image and run as a container. Why should infrastructure be any different? Since everything we write is "Infrastructure as Code", we believe that it should be treated the same way. This is the "Geodesic Way". Use containers+envs instead of unconventional wrappers, complicated folder structures and symlink hacks. Geodesic is the container for all your infrastructure automation needs that enables you to truly achieve SweetOps.

Geodesic is composed of two parts:

  1. It is an interactive command-line shell. The shell includes the *ultimate* mashup of cloud orchestration tools.
  Those tools are then integrated to work in concert with each other using a consistent framework.
  Installation of the shell is as easy as running a docker container.
  2. It is a distribution of essential services and [reference architectures](https://github.com/cloudposse?q=cloudposse.co). The distribution includes a collection of [100+ Free Terraform Modules](https://github.com/cloudposse?q=terraform-) and their [invocations](https://github.com/cloudposse/terraform-root-modules), dozens of preconfigured [Helmfiles](https://github.com/cloudposse/helmfiles), [Helm charts](https://github.com/cloudposse/charts) for CI/CD, VPN, SSH Bastion, Automatic DNS, Automatic TLS, Automatic Monitoring, Account Management, Log Collection, Load Balancing/Routing, Image Serving, and much more. What makes these charts even more valuable is that they were designed from the ground up to work well with each other and integrate with external services for authentication (SSO/OAuth2, MFA).

An organization may chose to leverage all of these components, or just the parts that make their life easier.
We recommend starting by using `geodesic` as a Docker base image (e.g. `FROM cloudposse/geodesic:...` pinned to a release and base OS) in your projects.

**Note**: Starting with Geodesic version 0.138.0, we distribute 2 versions of Geodesic Docker images, one based on [Alpine](https://alpinelinux.org/)
and one based on [Debian](https://debian.org), tagged `VERSION-BASE_OS`, e.g. `0.138.0-alpine`.
Prior to this, all Docker images were based on Alpine only and simply tagged `VERSION`. At present, the Alpine version is the most thoroughly tested
and best supported version, and the special Docker tag `latest` will continue to point to the latest Alpine version while this
remains the case. However, we encourage people to use the Debian version and report any issues by opening a GitHub issue,
so that we may eventually make it the preferred version, after which point the `latest` tag will point to latest Debian image. We
will maintain the `latest-alpine` and `latest-debian` Docker tags for those who want to commit to using one base OS or
the other but still want automatic updates.

Let's roll...

1. Review our [documentation](https://docs.cloudposse.com/geodesic/)
2. Check our [reference architectures](https://docs.cloudposse.com/reference-architectures/) to learn how we architect the infrastructure
3. Use our [coldstart automation](https://github.com/cloudposse/reference-architectures) to get started quickly
4. Quickly provision [kops clusters](docs/kops.md)

## Usage



In general we recommend creating a customized version of Geodesic by creating your own Dockerfile starting with
```
ARG VERSION=0.138.0
ARG OS=debian
FROM cloudposse/geodesic:$VERSION-$OS

# Add configuration options such as setting a custom BANNER,
# turning on built-in support for aws-vault or aws-okta,
# setting kops configuration parameters, etc. here

ENV BANNER="my-custom-geodesic"
```
You can see some example configuration options to include in [Dockerfile.options](./Dockerfile.options).

You can also add extra commands by installing "packages". Both Alpine and Debian have a large selection
of packages to choose from. Cloud Posse also provides a large set of packages for installing common DevOps commands
and utilities via [cloudposse/packages](https://github.com/cloudposse/packages).
The package repositories are pre-installed in Geodesic, all you need to do is add the packages you want
via `RUN` commands in your Dockerfile.

#### Installing packages in Alpine

Under Alpine, you install a package by specifying a package name and a repository label (if not the default repository).
(You can also specify a version, see [the Alpine documentation](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management#Advanced_APK_Usage)
for details). In addition to the default package repository, Geodesic installs 3 others:

| Repository Label | Repository Name|
|------------------|----------------|
| @testing | edge/testing |
| @community | edge/community |
| @cloudposse | cloudposse/packages |

As always, because of Docker layer caching, you should start your command line by updating the repo indexes,
and then add your packages. Alpine uses [`apk`](https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management).
So, to install [Teleport](https://gravitational.com/teleport) support from the Cloud Posse package repository,
pinned to version 4.2.x (which is the last to support Alpine), we can add this to our Dockerfile:

```
RUN apk update && apk add -u teleport@cloudposse=~4.2
```

#### Installing packages in Debian

Debian uses [`apt`](https://wiki.debian.org/Apt) for package management and we generally recommend using
the [`apt-get`](https://www.debian.org/doc/manuals/apt-guide/ch2.en.html) command to install packages.
In addition to the default repositories, Geodesic pre-installs the Cloud Posse [package](https://github.com/cloudposse/packages) repository
and the Google Cloud SDK package repository. Unlike with `apk`, you do not need to specify a package repository when
installing a package because all repositories will be searched for it.
Also unlike `apk`, `apt-get` does not let you specify a version range on the command line, only an exact version.
So to install the Google Cloud SDK at a specific version, you need to include a trailing `-0` to indicate
the package version. For example, to install version Google Cloud SDK 300.0.0:

```
RUN apt-get update && apt-get install -y google-cloud-sdk=300.0.0-0
```

Note the `-y` flag to `apt-get install`. That is required for scripted installation, otherwise the command
will ask for confirmation from the keyboard before installing a package.






---
title: ABOUT(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

about - About the Geodesic Cloud Automation Shell

## FEATURES

* **Secure** - TLS/PKI, OAuth2, MFA Everywhere, remote access VPN, [ultra secure bastion/jumphost](https://github.com/cloudposse/bastion) with audit capabilities and slack notifications, [IAM assumed roles](https://github.com/99designs/aws-vault/), automatic key rotation, encryption at rest, and VPCs
* **Repeatable** - 100% Infrastructure-as-Code with change automation and support for scriptable admin tasks in any language, including Terraform
* **Extensible** - A framework where everything can be extended to work the way you want to
* **Comprehensive** - our [helm charts library](https://github.com/cloudposse/charts) are designed to tightly integrate your cloud-platform with Github Teams and Slack Notifications and CI/CD systems like TravisCI, CircleCI or Jenkins
* **OpenSource** - Permissive [APACHE 2.0](LICENSE) license means no lock-in and no on-going license fees

## TECHNOLOGIES

At its core, Geodesic is a framework for provisioning cloud infrastructure and the applications that sit on top of it. We leverage as many existing tools as possible to facilitate cloud fabrication and administration. We're like the connective tissue that sits between all of the components of a modern cloud.

* [`atlantis`](https://www.runatlantis.io/) - GitOps style operations by Pull Request. Ideal for terraform, helm and helmfile.
* [`aws-vault`](https://github.com/99designs/aws-vault) for securely storing and accessing AWS credentials in an encrypted vault for the purpose of assuming IAM roles
* [`aws-cli`](https://github.com/aws/aws-cli/) for interacting directly with the AWS APIs
* [`chamber`](https://github.com/segmentio/chamber) for managing secrets with AWS SSM+KMS and exposing them as environment variables
* [`direnv`](https://direnv.net) for managing environment variables per project or globally
* [`helm`](https://github.com/kubernetes/helm/) for installing packages like Varnish or Apache on the Kubernetes cluster
* [`helmfile`](https://github.com/roboll/helmfile) for 12-factorizing chart values and installing chart collections
* [`kops`](https://github.com/kubernetes/kops/) for Kubernetes cluster orchestration
* [`kubectl`](https://kubernetes.io/docs/user-guide/kubectl-overview/) for controlling kubernetes resources like deployments or load balancers
* [`gcloud`, `gsutil`](https://cloud.google.com/sdk/) for integration with Google Cloud (e.g. GKE, GCE, Google Storage)
* [`gomplate`](https://github.com/hairyhenderson/gomplate/) for template rendering configuration files using the GoLang template engine. Supports lots of local and remote datasources
* [`goofys`](https://github.com/kahing/goofys/) a high-performance Amazon S3 file system for mounting encrypted S3 buckets that store cluster configurations and secrets
* [`terraform`](https://github.com/hashicorp/terraform/) for provisioning miscellaneous resources on pretty much any cloud
* [`tmate`](https://tmate.io) for remote terminal sharing with other engineers (pairing) and collaborative debugging

[](https://media.giphy.com/media/26FmS6BRnPVPo2FDq/source.gif)

## SEE MORE

Extensive documentation is provided on our [Documentation Hub](https://docs.cloudposse.com/geodesic). 
---
title: LOGO(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

logo - Explanation of the Geodesic Logo

## SYNOPSIS

![Geodesic Logo](https://raw.githubusercontent.com/cloudposse/geodesic/master/docs/geodesic-small.png)

In mathematics, a geodesic line is the shortest distance between two points on a sphere. It's also a solid structure composed of geometric shapes such as hexagons.

## DESCRIPTION

We like to think of geodesic as the shortest path to a rock-solid cloud infrastructure. The geodesic logo is a hexagon with a cube suspended at its center. The cube represents this geodesic container, which is central to everything and at the same time is what ties everything together.

But look a little closer and you’ll notice there’s much more to it. It's also an isometric shape of a cube with a missing piece. This represents its pluggable design, which lets anyone extend it to suit their vision.



## Share the Love

Like this project? Please give it a ★ on [our GitHub](https://github.com/cloudposse/geodesic)! (it helps us **a lot**)

Are you using this project or any of our other projects? Consider [leaving a testimonial][testimonial]. =)


## Related Projects

Check out these related projects.

- [Packages](https://github.com/cloudposse/packages) - Cloud Posse installer and distribution of native apps
- [Build Harness](https://github.com/cloudposse/dev) - Collection of Makefiles to facilitate building Golang projects, Dockerfiles, Helm charts, and more
- [terraform-root-modules](https://github.com/cloudposse/terraform-root-modules) - Collection of Terraform "root module" invocations for provisioning reference architectures
- [root.cloudposse.co](https://github.com/cloudposse/root.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Parent ("Root") Organization in AWS.
- [audit.cloudposse.co](https://github.com/cloudposse/audit.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for an Audit Logs Organization in AWS.
- [prod.cloudposse.co](https://github.com/cloudposse/prod.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Production Organization in AWS.
- [staging.cloudposse.co](https://github.com/cloudposse/staging.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Staging Organization in AWS.
- [dev.cloudposse.co](https://github.com/cloudposse/dev.cloudposse.co) - Example Terraform Reference Architecture of a Geodesic Module for a Development Sandbox Organization in AWS.



## Help

**Got a question?** We got answers.

File a GitHub [issue](https://github.com/cloudposse/geodesic/issues), send us an [email][email] or join our [Slack Community][slack].

[![README Commercial Support][readme_commercial_support_img]][readme_commercial_support_link]

## DevOps Accelerator for Startups


We are a [**DevOps Accelerator**][commercial_support]. We'll help you build your cloud infrastructure from the ground up so you can own it. Then we'll show you how to operate it and stick around for as long as you need us.

[![Learn More](https://img.shields.io/badge/learn%20more-success.svg?style=for-the-badge)][commercial_support]

Work directly with our team of DevOps experts via email, slack, and video conferencing.

We deliver 10x the value for a fraction of the cost of a full-time engineer. Our track record is not even funny. If you want things done right and you need it done FAST, then we're your best bet.

- **Reference Architecture.** You'll get everything you need from the ground up built using 100% infrastructure as code.
- **Release Engineering.** You'll have end-to-end CI/CD with unlimited staging environments.
- **Site Reliability Engineering.** You'll have total visibility into your apps and microservices.
- **Security Baseline.** You'll have built-in governance with accountability and audit logs for all changes.
- **GitOps.** You'll be able to operate your infrastructure via Pull Requests.
- **Training.** You'll receive hands-on training so your team can operate what we build.
- **Questions.** You'll have a direct line of communication between our teams via a Shared Slack channel.
- **Troubleshooting.** You'll get help to triage when things aren't working.
- **Code Reviews.** You'll receive constructive feedback on Pull Requests.
- **Bug Fixes.** We'll rapidly work with you to fix any bugs in our projects.

## Slack Community

Join our [Open Source Community][slack] on Slack. It's **FREE** for everyone! Our "SweetOps" community is where you get to talk with others who share a similar vision for how to rollout and manage infrastructure. This is the best place to talk shop, ask questions, solicit feedback, and work together as a community to build totally *sweet* infrastructure.

## Discourse Forums

Participate in our [Discourse Forums][discourse]. Here you'll find answers to commonly asked questions. Most questions will be related to the enormous number of projects we support on our GitHub. Come here to collaborate on answers, find solutions, and get ideas about the products and services we value. It only takes a minute to get started! Just sign in with SSO using your GitHub account.

## Newsletter

Sign up for [our newsletter][newsletter] that covers everything on our technology radar.  Receive updates on what we're up to on GitHub as well as awesome new projects we discover.

## Office Hours

[Join us every Wednesday via Zoom][office_hours] for our weekly "Lunch & Learn" sessions. It's **FREE** for everyone!

[![zoom](https://img.cloudposse.com/fit-in/200x200/https://cloudposse.com/wp-content/uploads/2019/08/Powered-by-Zoom.png")][office_hours]

## Contributing

### Bug Reports & Feature Requests

Please use the [issue tracker](https://github.com/cloudposse/geodesic/issues) to report any bugs or file feature requests.

### Developing

If you are interested in being a contributor and want to get involved in developing this project or [help out](https://cpco.io/help-out) with our other projects, we would love to hear from you! Shoot us an [email][email].

In general, PRs are welcome. We follow the typical "fork-and-pull" Git workflow.

 1. **Fork** the repo on GitHub
 2. **Clone** the project to your own machine
 3. **Commit** changes to your own branch
 4. **Push** your work back up to your fork
 5. Submit a **Pull Request** so that we can review your changes

**NOTE:** Be sure to merge the latest changes from "upstream" before making a pull request!


## Copyright

Copyright © 2017-2020 [Cloud Posse, LLC](https://cpco.io/copyright)



## License

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

See [LICENSE](LICENSE) for full details.

```text
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  https://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.
```









## Trademarks

All other trademarks referenced herein are the property of their respective owners.

## About

This project is maintained and funded by [Cloud Posse, LLC][website]. Like it? Please let us know by [leaving a testimonial][testimonial]!

[![Cloud Posse][logo]][website]

We're a [DevOps Professional Services][hire] company based in Los Angeles, CA. We ❤️  [Open Source Software][we_love_open_source].

We offer [paid support][commercial_support] on all of our projects.

Check out [our other projects][github], [follow us on twitter][twitter], [apply for a job][jobs], or [hire us][hire] to help with your cloud strategy and implementation.



### Contributors

|  [![Erik Osterman][osterman_avatar]][osterman_homepage]<br/>[Erik Osterman][osterman_homepage] | [![Igor Rodionov][goruha_avatar]][goruha_homepage]<br/>[Igor Rodionov][goruha_homepage] | [![Andriy Knysh][aknysh_avatar]][aknysh_homepage]<br/>[Andriy Knysh][aknysh_homepage] | [![Sarkis Varozian][sarkis_avatar]][sarkis_homepage]<br/>[Sarkis Varozian][sarkis_homepage] | [![Oscar Sullivan][osulli_avatar]][osulli_homepage]<br/>[Oscar Sullivan][osulli_homepage] |
|---|---|---|---|---|


  [osterman_homepage]: https://github.com/osterman
  [osterman_avatar]: http://s.gravatar.com/avatar/88c480d4f73b813904e00a5695a454cb?s=144


  [goruha_homepage]: https://github.com/goruha/
  [goruha_avatar]: http://s.gravatar.com/avatar/bc70834d32ed4517568a1feb0b9be7e2?s=144


  [aknysh_homepage]: https://github.com/aknysh/
  [aknysh_avatar]: https://avatars0.githubusercontent.com/u/7356997?v=4&u=ed9ce1c9151d552d985bdf5546772e14ef7ab617&s=144


  [sarkis_homepage]: https://github.com/sarkis
  [sarkis_avatar]: https://avatars3.githubusercontent.com/u/42673?s=144&v=4


  [osulli_homepage]: https://github.com/osulli
  [osulli_avatar]: https://github.com/osulli.png?size=150


[![README Footer][readme_footer_img]][readme_footer_link]
[![Beacon][beacon]][website]

  [logo]: https://cloudposse.com/logo-300x69.svg
  [docs]: https://cpco.io/docs?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=docs
  [website]: https://cpco.io/homepage?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=website
  [github]: https://cpco.io/github?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=github
  [jobs]: https://cpco.io/jobs?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=jobs
  [hire]: https://cpco.io/hire?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=hire
  [slack]: https://cpco.io/slack?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=slack
  [linkedin]: https://cpco.io/linkedin?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=linkedin
  [twitter]: https://cpco.io/twitter?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=twitter
  [testimonial]: https://cpco.io/leave-testimonial?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=testimonial
  [office_hours]: https://cloudposse.com/office-hours?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=office_hours
  [newsletter]: https://cpco.io/newsletter?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=newsletter
  [discourse]: https://ask.sweetops.com/?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=discourse
  [email]: https://cpco.io/email?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=email
  [commercial_support]: https://cpco.io/commercial-support?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=commercial_support
  [we_love_open_source]: https://cpco.io/we-love-open-source?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=we_love_open_source
  [terraform_modules]: https://cpco.io/terraform-modules?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=terraform_modules
  [readme_header_img]: https://cloudposse.com/readme/header/img
  [readme_header_link]: https://cloudposse.com/readme/header/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=readme_header_link
  [readme_footer_img]: https://cloudposse.com/readme/footer/img
  [readme_footer_link]: https://cloudposse.com/readme/footer/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=readme_footer_link
  [readme_commercial_support_img]: https://cloudposse.com/readme/commercial-support/img
  [readme_commercial_support_link]: https://cloudposse.com/readme/commercial-support/link?utm_source=github&utm_medium=readme&utm_campaign=cloudposse/geodesic&utm_content=readme_commercial_support_link
  [share_twitter]: https://twitter.com/intent/tweet/?text=Geodesic&url=https://github.com/cloudposse/geodesic
  [share_linkedin]: https://www.linkedin.com/shareArticle?mini=true&title=Geodesic&url=https://github.com/cloudposse/geodesic
  [share_reddit]: https://reddit.com/submit/?url=https://github.com/cloudposse/geodesic
  [share_facebook]: https://facebook.com/sharer/sharer.php?u=https://github.com/cloudposse/geodesic
  [share_googleplus]: https://plus.google.com/share?url=https://github.com/cloudposse/geodesic
  [share_email]: mailto:?subject=Geodesic&body=https://github.com/cloudposse/geodesic
  [beacon]: https://ga-beacon.cloudposse.com/UA-76589703-4/cloudposse/geodesic?pixel&cs=github&cm=readme&an=geodesic
