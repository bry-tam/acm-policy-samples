#  ACM Observability

## Description
Enables and configures ACM Observability (`MultiClusterObservability`) using ODF object storage.
Deploys the full observability stack including object storage, Thanos, and the Monitoring UI Plugin,
and annotates the hub `ManagedCluster` with alertmanager routing information.

## Dependencies
  - s3 Storage - Current configuration uses [ODF Operator](../../operators/data-foundation/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/observability/index)

Notes:
  - Deployed using the `ft-acm-observability--enabled` feature-flag placement
  - Storage depends on ODF; the OBC and NooBaa cert steps gate on the ODF policy being Compliant
  - MCOA (Managed Cluster Observability Addon) platform and user workload metrics are opt-in per cluster
    via the `observability-mcoa` label on the `ManagedCluster`
  - Alerting is disabled on the `MultiClusterObservability` by default (`mco-disable-alerting: 'true'`)
  - Observability pods are scheduled on infra nodes when present, worker nodes otherwise

## Implementation Details
Resources are deployed in dependency order using `extraDependencies`:

1. **Namespace** — `open-cluster-management-observability` with cluster-monitoring label
2. **ConsoleLink** — link added to the OCP console
3. **Pull secret** — copied from the global pull secret for image access
4. **ObjectBucketClaim** ← depends on ODF policy Compliant
5. **NooBaa cert Secret** ← depends on ODF policy Compliant
6. **Thanos object storage Secret** ← depends on OBC being Compliant
7. **MultiClusterObservability** ← depends on Thanos secret being Compliant
8. **UIPlugin** ← depends on MCO being Compliant

The `MultiClusterObservability` uses `hasNodesWithExactRoles "infra"` to schedule pods on infra
nodes when available, matching the klusterlet-infra node placement pattern.

The hub `ManagedCluster` is annotated with:
- `hub-alertmanager-url` — route hostname of the hub Alertmanager, used by managed clusters to forward alerts
- `hub-cluster-id` — truncated cluster ID (19 chars, dashes stripped) for Thanos identification
