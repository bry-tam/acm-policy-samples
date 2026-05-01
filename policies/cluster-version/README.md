#  Cluster Version

## Description
Manages the OpenShift cluster upgrade path. Ensures the `admin-acks` `ConfigMap` is present
with acknowledgements for Kubernetes API removals, which are required before OCP can proceed
with minor-version upgrades. An optional commented-out policy sets a target `ClusterVersion`
for use with TALM-orchestrated upgrades.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/updating_clusters/index)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - The `admin-acks` policy is enforced; the `ocp-upgrade` policy is commented out and intended
    for use with the Topology Aware Lifecycle Manager (TALM) Operator
  - Admin acks must be present before the cluster upgrade controller will proceed past a minor
    version boundary where deprecated Kubernetes APIs have been removed
  - Add a new `ack-` key to `admin-acks-configmap.yml` whenever a new OCP minor version
    introduces a Kubernetes API removal that requires acknowledgement

## Implementation Details
**`admin-acks-configmap`** — enforces a `ConfigMap` named `admin-acks` in the
`openshift-config` namespace. Each key is a string acknowledgement that the cluster
administrator has reviewed the corresponding Kubernetes API removal. The cluster upgrade
controller reads this ConfigMap and blocks the upgrade if a required acknowledgement is missing.

**`ocp-upgrade`** (commented out) — applies a `ClusterVersion` resource that sets a specific
`channel`, `upstream`, and `desiredUpdate.version`. When used with TALM, this policy is
activated on a per-cluster basis by TALM's `ClusterGroupUpgrade` controller to drive
coordinated rollouts across a fleet of clusters.
