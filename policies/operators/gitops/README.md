---
# OpenShift GitOps Operator

## Description
Deploys the OpenShift GitOps Operator and configures multiple `ArgoCD` instances using kustomize overlays to demonstrate a reusable base pattern. On the hub, also configures the PolicyGenerator plugin in the ArgoCD repo server and creates `ManagedClusterSetBinding` resources to enable multi-cluster `ApplicationSet` targeting.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest)

Notes:
  - Configures ArgoCD to use annotation-based resource tracking
  - Enables notifications on all instances but does not configure notification destinations
  - A `ConsoleLink` is created for each ArgoCD instance, named after its namespace
  - `argo-server-host.yml` uses `object-templates-raw` to iterate all `ArgoCD` instances and patch the server host to match the cluster route

## Implementation Details

**`gitops-operator`** — creates the `openshift-gitops-operator` and `openshift-gitops` namespaces and installs the `OperatorPolicy`.

**`gitops-instances`** — depends on `gitops-operator`. Uses `consolidateManifests: true` and kustomize overlays to deploy two `ArgoCD` instances from a shared `base/`:
  - `default` overlay (`openshift-gitops` namespace): patches the cluster-scoped instance for HA, adds an admin `ClusterRoleBinding`, and configures `GitOpsService` to expose the instance for `ApplicationSet` use
  - `dev` overlay (`argocd-dev` namespace): adds a namespace-scoped instance with a `RolloutManager` for progressive delivery

  After both instances are deployed, `argo-server-host.yml` reads each instance's `Route` and updates the ArgoCD server host annotation accordingly.

**`gitops-acm-policygenerator`** — hub-only (`gitops-acm-hub` PolicySet, placement `ft-acm-hub--exists`). Depends on `gitops-instances`. Patches the ArgoCD repo server with the ACM `PolicyGenerator` plugin, injects the cluster root CA `ConfigMap`, and uses `object-templates-raw` to create a `ManagedClusterSetBinding` for every `ManagedClusterSet` in `openshift-gitops`, enabling `ApplicationSet` generators to target managed clusters.

**`gitops-instance-status`** — depends on `gitops-instances`, runs `inform`. Uses `object-templates-raw` to enumerate all `ArgoCD` instances and verify each is in a healthy phase.
