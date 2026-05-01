#  ACM Remove Kubeadmin Password

## Description
Removes the kubeadmin password secret and its reference from Hive `ClusterDeployment` resources.
Intended to enforce removal of the temporary admin credential after clusters are provisioned.

> **WARNING: DO NOT USE** — This policy causes unintended consequences when the
> `adminPasswordSecretRef` is removed from `ClusterDeployment`. It is retained here for reference only.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/clusters/index)

Notes:
  - The kubeadmin secret must also be removed directly on the managed cluster
  - Do not enable this policy without fully understanding the impact on Hive cluster lifecycle operations

## Implementation Details
A hub-side template ranges over all `ClusterDeployment` resources. For each deployment that has an
`adminPasswordSecretRef` set:

1. Emits a `mustnothave` rule to delete the kubeadmin password `Secret`
2. Patches the `ClusterDeployment` to remove `adminPasswordSecretRef` from `clusterMetadata` and set
   `preserveOnDelete: true`

The `recreateOption` is set to `Always` when the cluster is already marked `preserveOnDelete` and is
installed (to force re-evaluation), and `IfRequired` otherwise.
