
function mfa() {
    local profile="${1:-${AWS_MFA_PROFILE}}"
    local file="${AWS_DATA_PATH}/${profile}.mfa"
    if [ -f "${file}" ]; then
        oathtool --base32 --totp "$(cat ${file})"
    elif [ -z "${profile}" ]; then
      echo "No MFA profile defined" >&2
    else
        echo "No MFA profile for $profile" >&2
    fi
}
