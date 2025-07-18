# ACM Klusterlet Infra
This policy will apply the following annotations to all `ManagedClusters` that contain nodes labeled as infra nodes.

Annotations applied to `ManagedCluster`
```
  open-cluster-management/nodeSelector: '{"node-role.kubernetes.io/infra":""}'
  open-cluster-management/tolerations: '[{"key":"node-role.kubernetes.io/infra","operator":"Exists"}]'
```

Additionally this policy will create a `AddOnDeploymentConfig` and will add a reference to it in all `ManagedClusterAddOn` in the cluster namespace.


## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/clusters/index#import-configuring-nodeselector-tolerations)

AddOnDeploymentConfig Docs: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/add-ons/index#setting-addondeploymentconfig-klusterlet-addons)

---
**Notes:**
  -
