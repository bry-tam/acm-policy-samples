---
# Descheduler Operator

## Description
Installs the Kube Descheduler operator into the `openshift-kube-descheduler-operator` namespace, enabling eviction of pods that violate scheduling policies so the scheduler can place them on more appropriate nodes.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/nodes/evicting-pods-using-the-descheduler)

Notes:
  - Targets clusters labeled `descheduler=enabled` via the `ft-descheduler--enabled` placement
  - Uses `upgradeApproval: Automatic` — pin `startingCSV` and `versions` to lock to a specific release
  - Does not deploy a KubeDescheduler instance — only installs the operator
