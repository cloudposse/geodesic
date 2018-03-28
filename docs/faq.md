# FAQ

## Error: Cannot list directory

```
$ ls /s3
ls: reading directory '.': I/O error
```

This means your AWS credentials have expired. Re-run `assume-role`.

## Error: Cannot unmount folder
```bash
$ s3 unmount
umount: can't unmount /s3: Resource busy
```

This means some process (maybe you) is in the directory. Try running `cd /` and rerun the unmount.

## What are the caveats?

* While the underlying tools support multiple cloud providers, we are currently only testing with AWS. Pull Requests welcome.
* Geodesic is tested on Linux and OSX. If you use Windows, we'd be a happy to work with you to get it working there as well


