#### `assume_active_aws_role`
For the case where you have an active `aws-vault` server but the current shell is not using it, 
you can run `assume_active_aws_role` to assume the role being served by the server.  Normally 
this is run automatically for you when the shell starts but if you start server later, you can 
now run this manually.

#### Source

These commands are defined in [aws-vault.sh](../rootfs/etc/profile.d/aws-vault.sh)