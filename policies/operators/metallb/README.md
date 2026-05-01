# MetalLB Operator
Installs the MetalLB Operator.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/load-balancing-with-metallb)

---
**Notes:**
  - Pinned to a specific CSV version via `upgradeApproval: None` and `spec.versions`. Update both `versions` and `subscription.startingCSV` to advance to a new release.
  - Does not deploy a MetalLB instance — only installs the operator.
