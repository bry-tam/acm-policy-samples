# ACM Ensure Placement Toleration
Policy ensures every `Placement` includes specific tolerations to prevent issues in event there are network issues between the hub and managed clusters.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/gitops/index#tolerations-config)

---
**Notes:**
  - Without the tolerations unexpected behavior can occur such as the removal of an application or Policy.
