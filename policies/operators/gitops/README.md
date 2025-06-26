# OpenShift GitOps Operator
Installs the OpenShift GitOps operator and example instances of ArgoCD.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_gitops/latest)

---
**Notes:**
  - Includes policy to migrate from openshift-operators namespace in GitOps 1.9 to openshift-gitops-operator in GitOps 1.10
  - For ACM clusters will:
    - Add the PolicyGenerator to the repo server component
    - Add a Placement and GitOpsCluster to openshift-gitops namespace to enable use of ApplicationSets from ACM
  - Enables notifications but does not configure any notifications
  - Demonstrates using kustomize to create multiple ArgoCD instances.  The "default" configures openshift-gitops instance that is deployed by operator to be HA along with other settings.  Dev instances shows adding a namespace bound Argo instance.  Kustomize with the policies allows reusing most of the config for each instance to have a standard configuration that the instance can override.
  - Configures Argo to use annotations for resource tracking.
  - Adds a ConsoleLink for each instance named after the namespace it is configured in.
