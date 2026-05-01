#  ACM Cluster Addon Resource Configuration

## Description
Sets memory resource requests and limits for the `governance-policy-framework` and `config-policy-controller`
addon deployments on every managed cluster. Addresses OOMKill conditions on clusters where ACM governance
pods exceed default memory limits.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.15

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/add-ons/acm-managed-adv-config#setting-addondeploymentconfig-klusterlet-addons)

Notes:
  - Deployed to hub only; the hub propagates resource constraints to all managed clusters via ClusterManagementAddOn
  - `AddOnDeploymentConfig` uses `mustonlyhave` to enforce exact resource values
  - Memory requests: 512Mi / limits: 1024Mi for both addon containers

## Implementation Details
The policy manages two resources:

**AddOnDeploymentConfig** (`clusteraddon-resource-config`) — defines the resource requirements applied to the
addon agent pods on each managed cluster:
- `governance-policy-framework-addon` container in the `governance-policy-framework` deployment
- `config-policy-controller` container in the `config-policy-controller` deployment

**ClusterManagementAddOn patch** — a hub-side template ranges over existing `ClusterManagementAddOn` resources
and patches `governance-policy-framework` and `config-policy-controller` to reference `clusteraddon-resource-config`
as their `defaultConfig`. This causes ACM to apply the `AddOnDeploymentConfig` to every managed cluster
without per-cluster configuration.

The template preserves existing `addOnMeta` and `installStrategy` fields using `toRawJson | toLiteral` to
avoid overwriting fields managed by ACM itself.
