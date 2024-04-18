This policy will apply the following annotations to all `ManagedClusters` that contain nodes labeled as infra nodes.

For the policies in this repo the `inframachines` label on the ManagedCluster is used to activate the Policy which creates the Infra MachineSet.  

Annotations applied to `ManagedCluster`
```
  open-cluster-management/nodeSelector: '{"node-role.kubernetes.io/infra":""}'
  open-cluster-management/tolerations: '[{"key":"node-role.kubernetes.io/infra","operator":"Exists"}]'
```

Additionally this policy will create a `AddOnDeploymentConfig` and will add a reference to it in all `ManagedClusterAddOn` in the cluster namespace.