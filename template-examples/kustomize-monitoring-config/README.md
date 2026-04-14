# Cluster Monitoring Config with Kustomize
This approach used per-cluster overlays to configure the cluster-monitoring-config ConfigMap when ACM Observability is enabled.

Changes in ACM 2.15 have broken the configuration demonstrated here.   The Alertmanager Accessor and Router-CA secret names used in the `additionalAlertmanagerConfigs` section now includes an identifer suffix for the hub cluster.

This example could be updated to account for that change, but currently the code does not.

## Dependencies
  - None

## Details
ACM Minimal Version: None

---
**Notes:**
  - kustomization.yaml in the cluster overlay calls a helm chart in [./components/cluster-monitoring-config](./components/cluster-monitoring-config/) directory.
  - Allows control of retention, storage, resources, nodeSelectors, and tolerations
  - Requirers the Cluster Id from the cluster to be in the values file.
