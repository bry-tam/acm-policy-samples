#  ARO Merge RH Pull Secret

## Description
Merges a Red Hat pull secret into the pull secret of ARO (Azure Red Hat OpenShift) managed clusters.
ARO clusters ship with a pull secret that contains only the `arosvc.azurecr.io` registry credential.
This policy adds the RH pull secret from the hub so that managed ARO clusters can pull Red Hat
container images from `registry.redhat.io` and other authenticated registries.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [ARO: Add or update pull secret](https://learn.microsoft.com/en-us/azure/openshift/howto-add-update-pull-secret)

Notes:
  - The hub cluster pull secret (`openshift-config/pull-secret`) must contain the RH pull secret
  - The `arosvc.azurecr.io` credential is always preserved from the managed cluster's existing pull secret
  - All other credentials are taken from the hub pull secret
  - Deployed to clusters labeled `cloud=Azure` via `ft-cloud--azure`; the prepare step runs on the hub only

## Implementation Details
The policy uses two separate placements to stage the secret propagation safely:

### Hub policy — `rh-pull-secret-prepare`
Runs on the hub only. Searches all policies in the policy namespace for `rh-pull-secret-merge`
to discover the namespace where the propagated secret should live, then copies the hub
`openshift-config/pull-secret` data into a `rh-pull-secret` Secret in that namespace using
`copySecretData`. This staged secret is what ACM propagates to managed clusters.

### Managed cluster policy — `rh-pull-secret-merge`
Two manifests applied in order:

1. **`rh-pull-secret-merge`** — propagates the staged `rh-pull-secret` from the hub to
   `openshift-config/rh-pull-secret` on the managed cluster using a hub-side `copySecretData`
   template. This makes the RH pull secret available locally on the managed cluster.

2. **`merge-pull-secret-with-aro`** ← depends on `rh-pull-secret-merge` being Compliant —
   reads both `openshift-config/pull-secret` (the ARO pull secret) and
   `openshift-config/rh-pull-secret` (the propagated RH pull secret), then writes a merged
   result back to `openshift-config/pull-secret` containing:
   - The `arosvc.azurecr.io` auth from the managed cluster's existing pull secret
   - All other auths from the RH pull secret (any `arosvc.azurecr.io` entry in the RH secret is skipped)
