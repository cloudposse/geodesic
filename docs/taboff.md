---
title: taboff and tabon (1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

`taboff`, `tabon` - control `bash` command completion

## SYNOPSIS

By default, `bash` command completion is turned on, and typing <tab> on the command line will trigger 
auto-completion of the current command. This causes problems, however, if you are pasting shell 
commands from a file that uses tabs for indenting. In this case, you can now use `taboff` to disable 
this special handling of the <tab> character, paste your text with tabs, and then use `tabon` to 
restore tab completion.

## SOURCE

These commands are defined in [/etc/profile.d/aliases.sh](../rootfs/etc/profile.d/aliases.sh)
