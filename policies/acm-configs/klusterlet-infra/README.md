#  ACM Klusterlet Infra Node Placement

## Description
Schedules ACM klusterlet addon pods onto infra nodes for clusters that have them, and onto worker
nodes for clusters that do not. Prevents ACM agents from consuming resources on application nodes
in environments where infra node separation is enforced.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [ManagedCluster nodeSelector/tolerations](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/clusters/index#import-configuring-nodeselector-tolerations)

Documentation: [AddOnDeploymentConfig](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/add-ons/index#setting-addondeploymentconfig-klusterlet-addons)

Notes:
  - Deployed to hub only; acts on all managed clusters
  - A cluster is treated as having infra nodes when it contains a node labeled `node-role.kubernetes.io/infra`
    but not `node-role.kubernetes.io/storage`
  - Creates two `AddOnDeploymentConfig` resources: `infra-deploy-config` and `worker-deploy-config`
  - All `ManagedClusterAddOn` resources in each cluster's namespace are patched to reference the appropriate config

## Implementation Details
The policy uses `ManagedClusterInfo` (which includes node labels) rather than `ManagedCluster` to detect
infra nodes without requiring direct cluster access.

For each managed cluster the template:

1. Inspects `status.nodeList` for a node with `node-role.kubernetes.io/infra` present and
   `node-role.kubernetes.io/storage` absent — this indicates a dedicated infra node
2. Sets `open-cluster-management/nodeSelector` and `open-cluster-management/tolerations` annotations
   on the `ManagedCluster` to direct ACM to schedule klusterlet pods on `infra` or `worker` nodes
3. Patches every `ManagedClusterAddOn` in the cluster namespace with a `configs` reference to either
   `infra-deploy-config` or `worker-deploy-config`

The two `AddOnDeploymentConfig` resources define `nodePlacement` with the matching `nodeSelector`
and `tolerations` that are propagated to addon agent deployments on the managed cluster.
