---
# Cert-Manager Operator

## Description
Deploys the cert-manager Operator and configures it to trust the cluster-wide CA bundle. Includes monitoring integration via a `ServiceMonitor` and an example CA-backed `ClusterIssuer` for issuing certificates.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.14

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#cert-manager-operator-for-red-hat-openshift)

Notes:
  - The `ClusterIssuer` uses a self-signed CA secret; production environments should replace this with an appropriate PKI
  - The `ServiceMonitor` enables Prometheus scraping of cert-manager metrics; no alerting rules are included
  - The trusted-CA `ConfigMap` is injected into cert-manager so it inherits the cluster proxy CA bundle
  - Requires ACM 2.14 for the `fail` template function used in the health check

## Implementation Details

**`cert-manager-operator`** — deploys the `cert-manager` namespace, injects the cluster trusted-CA `ConfigMap`, installs the `OperatorPolicy`, and runs an `InformOnly` health check (`cert-manager-status`) that uses `object-templates-raw` to verify every `Deployment` in the `cert-manager` namespace is fully available. Also creates the `openshift-cert-manager` namespace and the `Role`, `RoleBinding`, and `ServiceMonitor` needed for Prometheus scraping.

**`cert-manager-clusterissuer`** — depends on `cert-manager-operator`. Deploys the CA `Secret` and then the `ClusterIssuer` (gated via `extraDependencies` on the secret being compliant).
