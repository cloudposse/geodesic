function help() {
cat<<__EOF__
Available commands:
  leave-role      Leave the current role; run this to release your session
  assume-role     Assume a new role; run this to renew your session
  setup-role      Setup a new role; run this to configure your AWS profile
  secrets         Manage secrets
  init-terraform  Configure terraform backend for S3

__EOF__
}
