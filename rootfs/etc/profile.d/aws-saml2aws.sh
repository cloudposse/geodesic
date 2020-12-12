#!/usr/bin/env bash

if [[ $GEODESIC_TRACE =~ saml ]]; then
	export _GEODESIC_TRACE_SAML=true
else
	unset _GEODESIC_TRACE_SAML
fi

if [ "${AWS_SAML2AWS_ENABLED}" == "true" ]; then
	[[ -n $_GEODESIC_TRACE_SAML ]] && echo "trace: Executing aws-saml2aws.sh"
	if command -v saml2aws >/dev/null; then
		[[ -n $_GEODESIC_TRACE_SAML ]] && green "trace: saml2aws installed"
	else
		[[ -n $_GEODESIC_TRACE_SAML ]] && red "trace: saml2aws not installed"
		exit 1
	fi

	ln -sf /localhost/.saml2aws ${HOME}
fi
