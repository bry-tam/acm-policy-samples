#  ACM Ensure Placement Toleration

## Description
Ensures every `Placement` on the hub includes tolerations for unreachable and unavailable clusters.
Without these tolerations ACM may remove applications or policies from clusters that temporarily
lose connectivity to the hub.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/gitops/index#tolerations-config)

Notes:
  - Deployed to hub only; acts on all Placements across all namespaces
  - Adds `cluster.open-cluster-management.io/unreachable` and `cluster.open-cluster-management.io/unavailable` tolerations
  - Existing tolerations on each Placement are preserved

## Implementation Details
A hub-side template ranges over all `Placement` resources and emits a `musthave` patch for each one.
The template tracks whether each toleration key is already present and appends only the missing ones,
preserving any existing toleration values and `tolerationSeconds` fields.

The two tolerations enforced:

| Key | Effect |
|-----|--------|
| `cluster.open-cluster-management.io/unreachable` | Keeps decisions in place when hub cannot reach the cluster |
| `cluster.open-cluster-management.io/unavailable` | Keeps decisions in place when the cluster API is unavailable |
