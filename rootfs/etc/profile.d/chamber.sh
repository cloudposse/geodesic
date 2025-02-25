# This is a workaround for https://github.com/moby/buildkit/issues/5775
#
# The `chamber` command (https://github.com/segmentio/chamber) is a CLI for managing secrets.
# It is installed in Geodesic and referenced in various documentation.
#
# Chamber works with AWS SSM Parameter store to save encrypted parameters.
# By default, in uses a KMS key with the alias `parameter_store_key`
# to encrypt and decrypt the parameters. Geodesic supports using
# the AWS default key, with alias `ssm`, or a custom key.
#
# However, due to the issue with buildkit mentioned above,
# setting the required environment variable in the Dockerfile
# leads to a warning about it being a secret stored in the image.
#
# So, as a workaround, we allow you to set `CHAMBER_KMS_ALIAS` instead,
# and we will set the `CHAMBER_KMS_KEY_ALIAS` environment variable for you here.
#

if [[ -z "$CHAMBER_KMS_KEY_ALIAS" ]] && [[ -n "$CHAMBER_KMS_ALIAS" ]]; then
	export CHAMBER_KMS_KEY_ALIAS="$CHAMBER_KMS_ALIAS"
	unset CHAMBER_KMS_ALIAS
fi
