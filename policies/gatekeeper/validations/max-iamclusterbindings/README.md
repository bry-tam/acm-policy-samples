#  Max IAM Cluster Bindings

## Description
Deploys a Gatekeeper `ConstraintTemplate` and `Constraint` that enforce a maximum number of
users bound to a specified `ClusterRole` across all `ClusterRoleBindings`. Users within
`Group` subjects are expanded and counted individually. `ServiceAccount` subjects are ignored.
This replaces the behavior of the deprecated ACM `IAMPolicy` controller.

## Dependencies
  - [Gatekeeper Operator](../../../operators/gatekeeper/) — the `gatekeeper-instance` policy
    must be Compliant before this policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/governance/index#gatekeeper-policy-overview)

Notes:
  - Applied to clusters labeled `iam-maxbindings=enabled` via `ft-iam-maxbindings--enabled`
  - Gatekeeper must have `ClusterRoleBinding` and `Group` sync data available; the sync
    `Config` is managed by the Gatekeeper Operator policy at
    [../../../operators/gatekeeper/sync-configmap.yml](../../../operators/gatekeeper/sync-configmap.yml)
  - `informGatekeeperPolicies: false` keeps ACM from wrapping the Gatekeeper resources in
    an additional ConfigurationPolicy audit layer
  - The `ignoreClusterRoleBindings` parameter accepts a list of `ClusterRoleBinding` names
    to exclude from the count (e.g. system-managed bindings)

## Implementation Details
**`maxiamclusterbindings-constrainttemplate`** — installs the `MaxIAMClusterBindings`
`ConstraintTemplate` with a Rego policy and a shared `lib.helpers` library. On each admission
request for a `ClusterRoleBinding`, the policy:
1. Collects all existing `ClusterRoleBindings` that reference the target `ClusterRole` from
   Gatekeeper's sync cache, excluding the binding under review and any names in
   `ignoreClusterRoleBindings`
2. Expands `Group` subjects to their member user names using the synced `Group` inventory
3. Unions the existing subject set with the subjects from the incoming request
4. Denies the request when the total unique user count exceeds `maxClusterRoleBindingUsers`

**`max-cluster-admins`** — installs the `MaxIAMClusterBindings` `Constraint` targeting
`rbac.authorization.k8s.io/v1 ClusterRoleBinding` resources. Default configuration:
  - `clusterRole: cluster-admin`
  - `maxClusterRoleBindingUsers: 10`
  - `ignoreClusterRoleBindings: ["iam-max-groups"]`
