# This is the local message of the day (motd) that is displayed when you log into the container.
# It is sourced from /etc/profile.d/motd.sh as a bash script so that it can interpolate variables.

cat << EOF
IMPORTANT:
# Unless there were errors reported above,
#  * Configuration from your host \$HOME directory should be available
#  * under both \`${LOCAL_HOME}\` and \`${HOME}\`.
#  * Your AWS configuration should be available at \`${AWS_CONFIG_FILE}\`.
#  * Your host AWS credentials should be available.
#  * Use Leapp on your host computer to manage your credentials.
#  * Leapp is free, open source, and available from https://leapp.cloud
#  * Use the AWS_PROFILE environment variable to manage your AWS IAM role, or
#  * you can interactively select AWS profiles via the \`assume-role\` command,
#  * which will launch a subshell with your selected profile set.


EOF
