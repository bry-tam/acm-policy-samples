---
# NMState Operator

## Description
Installs the Kubernetes NMState operator into the `openshift-nmstate` namespace, enabling declarative node network configuration management via `NodeNetworkConfigurationPolicy` resources.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/kubernetes-nmstate)

Notes:
  - Targets clusters labeled `nmstate=enabled` via the `ft-nmstate--enabled` placement
  - Uses `upgradeApproval: Automatic` — pin `startingCSV` and `versions` to lock to a specific release
