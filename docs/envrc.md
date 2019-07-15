---
title: envrc (1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

`envrc` - `direnv` configuration file for environment variables

## SYNOPSIS

Every time the prompt is displayed, `direnv` checks for the existence of an `.envrc` file in the current and parent directories. If the file exists (and is authorized), it is evaluated in a bash sub-shell where all exported variables are captured and then exported to the current shell.

## HELPERS

Geodesic provides a number of helpers.

### Terraform

By adding `use terraform` to your `.envrc`, it will set the environment suitable for use with terraform.

It also supports a version argument to indicate which version of terraform you wish to use in the current project.

For example, `use terraform 0.11` will set the current path to search `/usr/local/terraform/0.11/bin`. 

The following alpine packages are provided and can be installed by running:

Install Terraform 0.11 by running: 

  `apk add --update terraform_0.11@cloudposse`

Install Terraform 0.12 by 

  `apk add --update terraform_0.12@cloudposse`



## SOURCE

These commands are defined in `/etc/direnv/rc.d/terraform`
