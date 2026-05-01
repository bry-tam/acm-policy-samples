---
# External Secrets Operator

## Description
Deploys the community release of the External Secrets Operator (ESO) and applies the `OperatorConfig` to activate it. ESO synchronizes secrets from external providers (HashiCorp Vault, AWS Secrets Manager, Azure Key Vault, etc.) into OpenShift `Secret` objects. This policy installs the operator only; provider-specific `ClusterSecretStore` and `ExternalSecret` resources must be configured separately.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/security_and_compliance/external-secrets-operator-for-red-hat-openshift)

Notes:
  - This is the community-provided operator; the Red Hat supported release was not GA as of OCP 4.19
  - Does not configure `ClusterSecretStore` or `ExternalSecret` resources — those are provider-specific and must be added per environment

## Implementation Details

**`external-secrets-operator`** — creates the `external-secrets` namespace, installs the `OperatorPolicy`, and applies the `OperatorConfig` CR to enable the operator.
