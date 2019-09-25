---
title: assume_active_aws_role(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

`assume_active_aws_role` - assume a role provided by the `aws-vault` server

## SYNOPSIS

For the case where you have an active `aws-vault` server but the current shell is not using it, 
you can run `assume_active_aws_role` to assume the role being served by the server.  Normally 
this is run automatically for you when the shell starts but if you start server later, you can 
now run this manually.

## SOURCE

This command is defined in [/etc/profile.d/aws-vault.sh](../rootfs/etc/profile.d/aws-vault.sh)
