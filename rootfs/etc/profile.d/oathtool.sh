
function mfa() {
	local profile="${1:-${${AWS_MFA_PROFILE:-${AWS_DEFAULT_PROFILE}}}}"
	local file="${AWS_DATA_PATH}/${profile}.mfa"
	if [ -f "${file}" ]; then
		oathtool --base32 --totp "$(cat ${file})"
	else
		echo "No MFA profile for $profile"
	fi
}
