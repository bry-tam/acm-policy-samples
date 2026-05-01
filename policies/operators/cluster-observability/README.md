---
# Cluster Observability Operator

## Description
Deploys the Cluster Observability Operator (COO), which provides the `UIPlugin` API for extending the OpenShift console with observability dashboards. Includes an `InformOnly` health check that verifies the `Deployment` for each active `UIPlugin` instance is fully available.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/cluster_observability_operator/index)

## Implementation Details

**`cluster-observability-operator`** — creates the `openshift-cluster-observability-operator` namespace, deploys the `OperatorPolicy`, and runs an `InformOnly` health check (`cluster-observability-status`) that uses `object-templates-raw` to enumerate all `UIPlugin` instances and verify each corresponding `Deployment` in `openshift-clusterobservability-operator` is fully available.
