---
# ACS Sensor

## Description
Gets the ACS init-bundle TLS secrets into the `stackrox` namespace and creates the
`SecuredCluster` CR. Applies uniformly to every cluster labeled `acs` — hub and managed
alike — since the hub also runs its own local Sensor.

## Dependencies
  - `acs-central-init-bundle-cert` (from [`../central/`](../central/)) must be Compliant

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest)

Notes:
  - `acs-sensor` is bound to `ft-acs--exists` (any cluster labeled `acs`, hub or managed)
  - `hub-template-auth/` deploys the `ServiceAccount` and `ClusterRole`/`ClusterRoleBinding`
    that let this policy's hub templates read the three `-tls` secrets directly out of the
    hub's `stackrox` namespace (plus `ManagedCluster` objects, needed to resolve builtin
    hub template context like `$.ManagedClusterName`), instead of first syncing them into
    each cluster's replicated policy namespace
  - Each `propagate-*-tls.yml` skips itself on the hub's own instance via
    `{{hub (eq (index $.ManagedClusterLabels "local-cluster") "true") | skipObject hub}}`
    — the hub already owns these secrets natively (created by `central`'s init-bundle
    `Job`), so copying them from `stackrox` back onto itself would be a pointless
    circular hub→hub reference. `skipObject` must run as a hub template here since the
    decision depends on `$.ManagedClusterLabels`, a hub-only builtin; a skipped object's
    `ConfigurationPolicy` reports Compliant, so it doesn't block `SecuredCluster`'s
    `extraDependencies` gate on the hub either.

## Implementation Details

**`acs-sensor`** — depends on `acs-central-init-bundle-cert` (a different `PolicyGenerator`)
being Compliant. Sets `hubTemplateOptions.serviceAccountName: acs-hub-serviceaccount` so its
hub-side `copySecretData "stackrox" "<secret>"` templates are authorized (via
`hub-template-auth/`) to read straight from the hub's `stackrox` namespace, pulling the
three `-tls` secrets into the local `stackrox` namespace on whichever cluster the policy is
evaluated on — hub or managed alike, except the hub's own copy of each secret, which is
skipped (see notes above). Deploys `SecuredCluster` once all three secrets are present
(enforced via `extraDependencies`).
