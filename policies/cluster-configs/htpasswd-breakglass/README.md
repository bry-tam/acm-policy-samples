---
# HTPasswd BreakGlass

## Description
Configures an htpasswd IdentityProvider named `BreakGlass-Emergency` on all clusters, creating a local `redhat` user for emergency access when other identity providers are unavailable.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/configuring-identity-providers#configuring-htpasswd-identity-provider)

Notes:
  - Targets all clusters in the ClusterSet via the `env-bound-placement` placement
  - The htpasswd Secret is generated using the Sprig `htpasswd` function, which bcrypt-hashes the password at policy evaluation time
  - The OAuth object uses `musthave` so existing identity providers are preserved and not removed
  - **The password in `secret.yml` is a placeholder for the break-glass credential. In production, the password should be retrieved from a secure secrets manager such as HashiCorp Vault using a hub-side template lookup, rather than being stored in plaintext in the policy manifests.**
