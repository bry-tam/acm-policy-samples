---
# Data Foundation Operator

## Description
Deploys the OpenShift Data Foundation (ODF) Operator and configures a standalone MultiCloud Object Gateway (NooBaa) to provide S3-compatible object storage. The `StorageCluster` is configured for AWS-based deployments and should be updated to match your environment's storage backend.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_data_foundation/latest)

Notes:
  - Only the MultiCloud Object Gateway is deployed by default; update `storagecluster.yml` to enable full Ceph/Rook block and file storage
  - The operator channel tracks the cluster version and upgrades automatically with the cluster
  - `StorageSystem` is no longer required in OCP 4.19+; the health check skips it on newer clusters

## Implementation Details

**`odf-operator`** — creates the `openshift-storage` namespace and installs the `OperatorPolicy`.

**`odf-configure`** — depends on `odf-operator`. Enables the ODF console plugin, then deploys `StorageSystem` and `StorageCluster` to bring up the MultiCloud Object Gateway.

**`odf-operator-status`** — depends on `odf-configure`, runs `inform`. Uses `object-templates-raw` to verify all eight ODF operator `Deployment`s in `openshift-storage` are fully available, checks that the `StorageCluster` has `ReconcileComplete`, `Available`, and `Upgradeable` conditions all `True`, and (on OCP < 4.19) verifies the `StorageSystem` `VendorCsvReady` and `Available` conditions.
