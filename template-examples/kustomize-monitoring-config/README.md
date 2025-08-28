# Cluster Monitoring Config with Kustomize
This approach used per-cluster overlays to configure the cluster-monitoring-config ConfigMap when ACM Observability is enabled.

## Dependencies
  - None

## Details
ACM Minimal Version: None

---
**Notes:**
  - kustomization.yaml in the cluster overlay calls a helm chart in [./components/cluster-monitoring-config](./components/cluster-monitoring-config/) directory.
  - Allows control of retention, storage, resources, nodeSelectors, and tolerations
  - Requirers the Cluster Id from the cluster to be in the values file.
