---
# OpenShift Pipelines Operator

## Description
Deploys the OpenShift Pipelines Operator and configures `TektonConfig` and `TektonChains` for supply-chain security. Propagates the cluster global pull-secret into every namespace labeled `tekton.rh-reg-auth: true` so pipelines can pull from the Red Hat registry without per-namespace secret management.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_pipelines/latest)

Notes:
  - `TektonConfig` cleanup interval defaults to every minute; adjust to fit your environment
  - Pull-secret propagation uses `namespaceSelector` to target only labeled namespaces, not all namespaces

## Implementation Details

**`tekton-operator`** — creates the `openshift-pipelines` namespace and installs the `OperatorPolicy`.

**`tekton-rh-auth`** — depends on `tekton-operator`. Scoped to namespaces labeled `tekton.rh-reg-auth: true` via `namespaceSelector`. Uses a hub-side `copySecretData` template to copy the cluster global pull-secret from `openshift-config` into each matching namespace as a `Secret`, and ensures the `pipeline` `ServiceAccount` is present.

**`tekton-configure`** — depends on `tekton-operator`. Deploys `TektonChains` for artifact signing and a `TektonConfig` CR with automated `PipelineRun` cleanup configured.

**`tekton-operator-status`** — depends on `tekton-operator`, runs `inform`. Uses `object-templates-raw` to enumerate and verify all expected `openshift-pipelines` operator deployments are fully available.
