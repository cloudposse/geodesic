## What is the issue?

* Describe the problem and how to reproduce it.
* Describe the feature request or enhancement.

## Why is this an issue?

* Explain why this is a problem and what is the expected behavior.
* Explain why this feature request or enhancement is beneficial.

## Versions

### Your OS

```Bash
$ lsb_release -a

No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 18.10
Release:	18.10
Codename:	cosmic
```

### Geodesic Dockerfile

```Dockerfile
FROM cloudposse/terraform-root-modules:x.y.z as terraform-root-modules

FROM cloudposse/helmfiles:x.y.z as helmfiles

FROM cloudposse/geodesic:x.y.z
```

## Replication steps

* Clear, specific, and bullet-pointed steps to replicate the issue
