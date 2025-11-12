# ACM Remove kubeadmin password
Policy removes the kubeadmin password and reference from `ClusterDeployment`

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/gitops/index#tolerations-config)

---
**Notes:**
  - The kubeadmin also needs to be removed from the managed cluster.
