#### `chudo`/ `kudo` and `chundo`/`kundo`
Named in reference to the `sudo` command and "undo" operation, these commands replace 2 previous commands that create subshells with secrets that enable `kops` to control a Kubernetes cluster.

Previously:
```
cd /conf/kops
make deps
make kops/shell
```
or
```
chamber exec kops -- bash -l
```
Now: `kudo` or `chdo kops` import those secrets into the current shell rather than creating a subshell. 

Previously: you removed the secrets from the shell by exiting the shell.
Now: `kundo` or `chundo kops` remove the secrets from the current shell.

`kudo` is shorthand to just import the `chamber` secrets in the `kops` service. `chudo` is more generic, taking a list of services, e.g. `chudo kops datadog codefresh`. Likewise, `chundo` takes a list of services, and `kundo` is just an alias for `chundo kops`.

#### Source

These commands are defined in [aliases.sh](../rootfs/etc/profile.d/aliases.sh)
