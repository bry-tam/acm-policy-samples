# Topology Aware Lifecycle Management Operator
Installs the Topology Aware Lifecycle Operator.

## Dependencies
  - ACM

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/edge_computing/cnf-talm-for-cluster-updates#cnf-about-topology-aware-lifecycle-manager-config_cnf-topology-aware-lifecycle-manager)

---
**Notes:**
  - Only should be deployed to ACM hub
  - Deploys to openshift-talm-operator namespace instead of default openshift-operators namespace.
  - Channel must be set to stable or deployment failed.  This may have been fixed in later versions.
