---
# File Integrity Operator

## Description
Deploys the File Integrity Operator and configures a `FileIntegrity` resource to scan all nodes regardless of taints. Includes an automatic cleaner that removes stale `FileIntegrityNodeStatus` objects for nodes that no longer exist, and an `InformOnly` health check that alerts when any node scan result is `Failed`.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.14

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/security_and_compliance/file-integrity-operator)

## Implementation Details

**`file-integrity-operator`** — creates the `openshift-file-integrity` namespace, installs the `OperatorPolicy`, deploys the `FileIntegrity` CR configured to scan all nodes (with a toleration for all taints), runs `object-templates-raw` to delete any `FileIntegrityNodeStatus` objects whose node no longer exists in the cluster, and runs an `InformOnly` `object-templates-raw` check that reports `NonCompliant` for any `FileIntegrityNodeStatus` with a `Failed` last result.
