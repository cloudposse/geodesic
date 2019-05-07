---
title: FAQ(1) | Geodesic
author:
- Erik Osterman
date: May 2019
---

## NAME

FAQ - Frequently Asked Questions

## QUESTIONS

### Does it work with Windows?

Yes! Geodesic runs on Windows 10, under the Windows Subsystem for Linux (WSL) for Ubuntu. 

### Error: Cannot list directory

```
$ ls /s3
ls: reading directory '.': I/O error
```

This means your AWS credentials have expired. Re-run `assume-role`.

### Error: Cannot unmount folder

```bash
$ s3 unmount
umount: can't unmount /s3: Resource busy
```

This means some process (maybe you) is in the directory. Try running `cd /` and rerun the unmount.

### What are the caveats?

* While the underlying tools support multiple cloud providers, we are currently only testing with AWS. Pull Requests welcome.

### Problems with `aws-vault`

Most problems are related to environment settings. 

Here are some things to try:

* Delete any `[default]` profile in `~/.aws/credentials` or `[profile default]` in `~/aws/config`
* Unset `AWS_SDK_LOAD_CONFIG`
* Unset `AWS_SHARED_CREDENTIALS_FILE`

If using `--server` mode, make sure you do not have credentials exported: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SECURITY_TOKEN`, `AWS_SESSION_TOKEN`

