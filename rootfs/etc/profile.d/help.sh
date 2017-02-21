function help() {
cat<<__EOF__
Available commands:
  cloud           Control your cloud
  leave-role      Leave the current role; run this to release your session
  assume-role     Assume a new role; run this to renew your session
  setup-role      Setup a new role; run this to configure your AWS profile

Run "cloud help" for additional commands

__EOF__
}
