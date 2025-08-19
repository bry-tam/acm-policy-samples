# Multi-cluster GitOps with ACM
The purpose of this policy is to create a GitOps instance on a cluster which makes use of ManagedServiceAccount and ClusterPermissions for authorizing an application team within the organization to have a single ArgoCD instance that can manage objects on multiple ManagedClusters.  By using the ClusterPermissions the control over access is still maintained by the OpenShift administrator, but this solution will remove the effort to configure the cluster access, ServiceAccount and Argo Cluster secret for each ManagedCluster.

The application teams would then be able to use a cluster generator in their ApplicationSet which would let them filter and choose which clusters their application is deployed to.  The labels from the ManagedCluster will be added to the cluster secret for this.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.11

  > This example was specifically written for ACM 2.11 limitations.  An updated example can be found in the [policies/application-defaults](../../policies/application-defaults/) directory

Documentation:
  - [Cluster Permissions](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.11/html-single/gitops/index#creating_a_cluster_permission)
  - [Argo respectRBAC setting](https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/#auto-respect-rbac-for-controller)

---
**Notes:**
  - The first example is for an imaginary team named Scooter.  The argo instance created will reflect this as will some of things like namespaces.
    - This instance only has permission to deploy cluster scoped objects for Gatekeeper
  - The second example is for an imaginary team named Fozzie.  The argo instance will have cluster scope for a namespace named "app-team-fozzie", and namespace scoped access for `deployments`, `configmaps`, `secrets` and such in the "app-team-fozzie" namespace
    - The app team should be able to create and edit their namespace though Argo, deploy their app to that namespace.  And not be able to access or deploy anywhere else within the cluster.
  - You could control which managed clusters are available to the app team by using label selectors in the `ManagedCluster` lookup in argocd-instances/team-scooter/managedserviceaccount.yml and argocd-instances/team-fozzie/managedserviceaccount.yml
  - The Argo instance is configured with `spec.controller.respectRBAC: normal`.  This causes Argo to not search and discover objects it isn't explicitly granted access to.
