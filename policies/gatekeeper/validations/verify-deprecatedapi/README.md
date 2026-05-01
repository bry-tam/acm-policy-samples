#  Verify Deprecated API

## Description
Deploys a Gatekeeper `ConstraintTemplate` and a set of per-Kubernetes-version `Constraints`
that block admission of resources using deprecated API versions. Each constraint is only
installed on clusters running at or above its target Kubernetes version, ensuring that
resources using removed API versions cannot be created or updated.

## Dependencies
  - [Gatekeeper Operator](../../../operators/gatekeeper/) — the `gatekeeper-instance` policy
    must be Compliant before this policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://kubernetes.io/docs/reference/using-api/deprecation-guide/)

Notes:
  - Applied to clusters labeled `verify-dep-api=enabled` via `ft-verify-dep-api--enabled`
  - Each constraint file uses a managed-cluster-side `semverCompare` check against the
    `kubeversion.open-cluster-management.io` cluster claim — if the version check fails the
    template emits nothing and no constraint is deployed
  - `informGatekeeperPolicies: false` keeps ACM from wrapping the Gatekeeper resources in
    an additional ConfigurationPolicy audit layer
  - These constraints apply to admission only; they do not audit resources already present
    in the cluster that were created with now-deprecated API versions

## Implementation Details
**`verifydeprecatedapi-constrainttemplate`** — installs the `VerifyDeprecatedAPI`
`ConstraintTemplate`. The Rego policy matches an incoming resource's `apiVersion` and `kind`
against the `kvs` parameter array. When a match is found it emits a violation message
indicating the deprecated API, the Kubernetes version where it was removed, and the target
replacement API. When `targetAPI` is `"None"` the message directs users to the Kubernetes
deprecation guide instead.

Six version-gated constraints are deployed, each conditioned on the cluster's Kubernetes
minor version:

| Manifest | Min k8s Version | Notable APIs removed |
|----------|-----------------|----------------------|
| `verifydeprecatedapi-1.16` | 1.16 | `apps/v1beta1`, `extensions/v1beta1` Deployments/ReplicaSets/DaemonSets |
| `verifydeprecatedapi-1.22` | 1.22 | `admissionregistration/v1beta1`, `apiextensions/v1beta1`, `networking/v1beta1` Ingress, `rbac/v1beta1` |
| `verifydeprecatedapi-1.25` | 1.25 | `batch/v1beta1` CronJob, `policy/v1beta1` PodDisruptionBudget and PodSecurityPolicy |
| `verifydeprecatedapi-1.26` | 1.26 | `flowcontrol.apiserver.k8s.io/v1beta1`, `autoscaling/v2beta2` |
| `verifydeprecatedapi-1.27` | 1.27 | `storage.k8s.io/v1beta1` CSIStorageCapacity |
| `verifydeprecatedapi-1.29` | 1.29 | `flowcontrol.apiserver.k8s.io/v1beta2` FlowSchema and PriorityLevelConfiguration |
