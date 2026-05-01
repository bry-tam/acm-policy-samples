---
# Advanced Cluster Security Operator

## Description
Deploys ACS Operator and creates a `Central` instance on the hub cluster and `SecuredCluster` on each managed cluster. Fully manages the init-bundle lifecycle, automatically rotating certificates before they expire. Two feature-flag labels on `ManagedCluster` objects (`acs=hub`, `acs=managed`) control which components are deployed to which clusters.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest)

## Implementation Details

**`acs-operator`** — deploys the `rhacs-operator` and `stackrox` namespaces plus the `OperatorPolicy` on both hub and managed clusters (bound to both `acs-operator-hub` and `acs-operator-managed` PolicySets).

**`acs-central`** — depends on `acs-operator`. Deploys the `Central` CR and a `ConsoleLink` on the hub. Includes an `InformOnly` health check (`acs-central-status`) that uses `object-templates-raw` to verify all four Central deployments (`central`, `central-db`, `scanner`, `scanner-db`) are fully available.

**`acs-central-init-bundle`** — depends on `acs-central`. Runs a `Job` on the hub (backed by a `ServiceAccount`, `Role`, and `RoleBinding`) that calls the ACS API to generate an init-bundle and writes the resulting TLS secrets to the `stackrox` namespace.

**`acs-central-init-bundle-cert`** — depends on `acs-central-init-bundle`. Combines a `CertificatePolicy` monitoring `sensor-tls` expiry with the hub `SecuredCluster` CR. The `SecuredCluster` is gated via `extraDependencies` on the cert policy being compliant (i.e., cert not yet expired).

**`acs-central-expired-certs`** — depends on `acs-central-init-bundle-cert` being **NonCompliant** (uses `ignorePending: true` to avoid always-pending state). Uses `complianceType: mustnothave` to delete the three expired TLS secrets and reset the init-bundle `Job`, triggering the bundle to be regenerated.

**`acs-sensor-sync-certs`** — depends on `acs-central-init-bundle-cert`. Uses `object-templates-raw` to copy the three `-tls` secrets from the `stackrox` namespace into the policy namespace so they can be accessed via hub templates by the managed-cluster policies.

**`acs-sensor`** — propagates the three `-tls` secrets to each managed cluster using hub-side `copySecretData` templates, then deploys `SecuredCluster` once all three secrets are present (enforced via `extraDependencies`).
