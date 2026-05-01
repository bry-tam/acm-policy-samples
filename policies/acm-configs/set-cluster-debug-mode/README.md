#  Set Cluster Debug Mode

## Description
Temporarily suspends ACM governance policy enforcement on a managed cluster by disabling the
`KlusterletAddonConfig` policy controller. Enables debugging and temporary configuration changes
that would otherwise be overridden by running policies. Debug mode automatically expires after
2 hours and restores normal policy enforcement.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: None

Notes:
  - Cannot be applied to the hub (`local-cluster` is excluded)
  - Debug mode is activated by setting the `cluster-debug-mode: enabled` label on the `ManagedCluster`
  - Debug mode expires automatically after 2 hours; the label is changed to `expired`
  - A companion `InformOnly` policy (`cluster-is-debug`) reports which clusters are in debug mode

## Implementation Details
A hub-side template ranges over all managed clusters (excluding `local-cluster`) and evaluates three
mutually exclusive states based on the `cluster-debug-mode` label and `cluster-debug-expires` annotation:

| State | Trigger | Action |
|---|---|---|
| **Enable** | Label is `enabled`, no expiration annotation | Sets expiration to `now + 2 hours`, disables policy controller |
| **Expire** | Label is `enabled`, expiration time has passed | Changes label to `expired`, re-enables policy controller |
| **Disable** | Label is absent or not `enabled` | Removes expiration annotation, enables policy controller |

The `KlusterletAddonConfig` `spec.policyController.enabled` field is set to `false` only when debug
mode is active and not yet expired. The `ManagedCluster` metadata (labels and annotations) is patched
using `mustonlyhave` with `metadataComplianceType` to enforce the exact state computed by the template.

**To enable debug mode on a cluster:**
```bash
oc label managedcluster <cluster-name> cluster-debug-mode=enabled
```

**To exit debug mode before expiration:**
```bash
oc label managedcluster <cluster-name> cluster-debug-mode-
```
