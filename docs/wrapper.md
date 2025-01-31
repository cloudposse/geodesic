---
title: wrapper(7) | Geodesic
author:
- Nuru
date: January 2025
---


## Name

  Wrapper - Geodesic wrapper script

## Synopsis

The wrapper is an executable shell script installed to launch a Geodesic container.
It is responsible for setting up the relationship between the host and the container,
such as mounting directories, exposing a TCP port, and forwarding the SSH agent.

## Description

Geodesic comes in 2 parts. The bulk of it is a Docker container image that contains a collection of tools and utilities
you hopefully will find useful. The other part is a wrapper script that makes it easy to interact with the container.
This is referred to as "the wrapper" in many places in the documentation.

When you "install" Geodesic, what you are actually installing is the wrapper script. The wrapper script is a shell script
pre-configured with the Docker image to use and other configuration. The wrapper name is configured
in the Makefile as `APP_NAME`, and for the basic Geodesic image is `geodesic`. Users are encouraged
to customize Geodesic and give it their own name.

In the documentation, wherever you see `geodesic`, you can replace it with your own `APP_NAME`.
