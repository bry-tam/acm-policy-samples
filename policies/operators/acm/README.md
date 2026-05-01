---
# Advanced Cluster Management Operator

## Description
Deploys the ACM Operator and manages the `MultiClusterHub` instance. Controls which version/channel is installed and moves the operator to infra nodes when they are available. Because ACM manages itself, the namespace is expected to already exist before this policy runs.

## Dependencies
  - [Cluster Observability](../cluster-observability/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest)

Notes:
  - The `OperatorPolicy` monitors health of the `multiclusterhub-operator` deployment only; it does not monitor the full ACM stack
  - ACM Observability and other ACM workload placement to infra nodes require separate policies
  - Deploys the multi-cluster alert UI plugin via `MultiClusterHub`
