# Advanced Cluster Management Operator
Configures the ACM Operator and manages `multicluterhub` instance.  Policy controls what version/channel is deployed and moves the operator to Infra nodes when they are available in the cluster.

As ACM is managing itself there is an expectation that ACM was likely installed by other means.

## Dependencies
  - [Cluster Observability](../cluster-observability/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest)

---
**Notes:**
  - Monitors health of operator deployment itself through the OperatorPolicy behavior.
    - Does not monitor all of ACM health, just the multiclusterhub-operator deployment
  - This will not configure ACM Observability or move other ACM workloads to infra nodes
  - Because ACM can't install ACM, the namespace is expected to already exist.
  - Deploys multi-cluster alert UI plugin
