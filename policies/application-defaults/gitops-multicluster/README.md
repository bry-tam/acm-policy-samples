# Multi-cluster GitOps with ACM
The purpose of this policy is to create a GitOps instance on a cluster which makes use of ManagedServiceAccount and ClusterPermissions for authorizing an application team within the organization to have a single ArgoCD instance that can manage objects on multiple ManagedClusters.  By using the ClusterPermissions the control over access is still maintained by the OpenShift administrator, but this solution will remove the effort to configure the cluster access, ServiceAccount and Argo Cluster secret for each ManagedCluster.

The application teams would then be able to use a cluster generator in their ApplicationSet which would let them filter and choose which clusters their application is deployed to.  The labels from the ManagedCluster will be added to the cluster secret for this.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.11

Documentation: TODO

---
**Notes:**
  - The example is for an imaginary team named Scooter.  The argo instance created will reflect this as will some of things like namespaces
  - You could control which managed clusters are available to the app team by using label selectors in the `ManagedCluster` lookup in argocd-instances/team-scooter/managedserviceaccount.yml
  -
