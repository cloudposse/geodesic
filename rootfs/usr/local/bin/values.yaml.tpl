smtp:
  ## SMTP_DOMAIN: Domain for SMTP server (e.g. cloudposse.com)
  domain: "{{ getenv "SMTP_DOMAIN" }}"
  username: "postmaster"
  password: "secret"
