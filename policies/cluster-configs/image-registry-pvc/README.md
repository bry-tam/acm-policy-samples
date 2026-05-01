---
# Image Registry — Portworx Storage

## Description
Configures the OpenShift image registry to use a 100Gi `ReadWriteMany` PVC backed by the `gp3-csi` AWS CSI StorageClass, enabling a highly-available two-replica registry deployment.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/registry/configuring-registry-storage-baremetal)

Notes:
  - Targets clusters labeled `storage=aws` via the `ft-storage--aws` placement
  - The registry Config is gated on the PVC being compliant to ensure the volume is bound before the registry is reconfigured
  - Adjust `spec.resources.requests.storage` in `pvc.yml` to match site capacity requirements
