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
  - Creates a per-addon `AddOnDeploymentConfig` (named `override-<addon-name>`) in each managed cluster's
    namespace instead of sharing a single hub-scoped config
  - Any `nodePlacement` an addon's existing `AddOnDeploymentConfig` already defines is preserved and merged
    with the generated infra/worker selector rather than being overwritten
  - All `ManagedClusterAddOn` resources in each cluster's namespace are patched to reference the generated
    per-addon config
  - `metadataComplianceType: musthave` is set on the generated objects so labels/annotations added by other
    controllers after creation don't cause the policy to flap between Compliant/NonCompliant

## Implementation Details
The policy uses `ManagedClusterInfo` (which includes node labels) rather than `ManagedCluster` to detect
infra nodes without requiring direct cluster access.

For each managed cluster the template:

1. Inspects `status.nodeList` for a node with `node-role.kubernetes.io/infra` present and
   `node-role.kubernetes.io/storage` absent — this indicates a dedicated infra node
2. Sets `open-cluster-management/nodeSelector` and `open-cluster-management/tolerations` annotations
   on the `ManagedCluster` to direct ACM to schedule klusterlet pods on `infra` or `worker` nodes
3. For each `ManagedClusterAddOn` in the cluster namespace, builds an `infra`/`worker` `nodePlacement`
   spec and merges in the `spec` of any `AddOnDeploymentConfig` the addon already references (tracked via
   the `org_addondeploymentconfig_name` annotation, or discovered from `status.configReferences` on first
   run), so unrelated settings on that config are not lost
4. Writes the merged spec to a `override-<addon-name>` `AddOnDeploymentConfig` in the cluster's namespace
   and patches the `ManagedClusterAddOn` to reference it

Because each addon gets its own generated config, changes are isolated per addon instead of being shared
across all addons on all clusters through the previous `infra-deploy-config`/`worker-deploy-config` pair.
