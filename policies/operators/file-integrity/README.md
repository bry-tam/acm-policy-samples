# File Integrity Operator
Installs the File Integrity Operator.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.14

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/security_and_compliance/file-integrity-operator)

---
**Notes:**
  - Configures default `FileIntegrity` resource to scan all nodes, regardless of taints
  - Includes policy to remove `FileIntegrityNodeStatus` for nodes that don't exist.
  - Includes health policy that will alert when `FileIntegrityNodeStatus` has last scan result Failed
