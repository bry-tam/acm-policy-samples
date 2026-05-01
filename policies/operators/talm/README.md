---
# Topology Aware Lifecycle Manager Operator

## Description
Deploys the Topology Aware Lifecycle Manager (TALM) Operator on the ACM hub cluster. TALM orchestrates cluster lifecycle operations (upgrades, configuration rollouts) across large fleets of edge clusters using `ClusterGroupUpgrade` resources, respecting topology constraints to limit the blast radius of concurrent changes.

## Dependencies
  - [Advanced Cluster Management Operator](../acm/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/edge_computing/cnf-talm-for-cluster-updates#cnf-about-topology-aware-lifecycle-manager-config_cnf-topology-aware-lifecycle-manager)

Notes:
  - Deploys to the hub only via the `ft-acm-hub--exists` placement
  - Installs into `openshift-talm-operator` rather than the default `openshift-operators` namespace to allow managed InstallPlan approval
  - The operator subscription uses the `stable` channel

## Implementation Details

**`talm-operator`** — creates the `openshift-talm-operator` namespace and installs the `OperatorPolicy`.
