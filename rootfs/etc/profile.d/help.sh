#!/usr/bin/env bash
function help() {
cat<<__EOF__
Available commands:
  leave-role      Leave the current role; run this to release your session
  assume-role     Assume a new role; run this to renew your session
  setup-role      Setup a new role; run this to configure your AWS profile
  s3              Manage s3 buckets with fstab
  init-terraform  Configure terraform project backend to use S3

__EOF__
}
