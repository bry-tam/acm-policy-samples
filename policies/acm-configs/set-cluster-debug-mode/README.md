# Set Cluster Debug Mode
Policy will act on `ManagedClusters with specific label to disable Policy Governance Framework.  This will remove policy management from the cluster allowing debug and other activites which a policy might override temporary configuration.

When a cluster is put into debug mode, the ConfigurationPolicies are removed from the managed cluster.  Testing putting a cluster into and out of debug mode has seemed safe, without impact to pruneObjectBehavior settings.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: None

---
**Notes:**
  - Adding the `cluster-debug-mode: enabled` label will perform the following actions
    - Disable KlusterletAddonConfig `spec.policyController.enabled: false`
    - Add annotation with expiration date/time to automatically place cluster back into managed state
    - Add ManagedCluster as nonComplient until label is removed.
  - Removing the `cluster-debug-mode: enabled` label will perform the following actions
    - Enable KlusterletAddonConfig `spec.policyController.enabled: true`
    - Leave the annotation for expiration date/time.  This is done so if it is re-enabled the time is not extended.
    - Expect ManagedCluster would then report as compliant
