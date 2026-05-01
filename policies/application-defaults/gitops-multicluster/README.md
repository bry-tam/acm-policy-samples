#  Multi-cluster GitOps with ACM

## Description
Deploys a team-scoped ArgoCD instance that can manage applications across multiple managed clusters
from a single control plane. Uses `ManagedServiceAccount` and `ClusterPermission` to automate cluster
access configuration, removing the need for operators to manually create ServiceAccounts and Argo
cluster secrets for each target cluster. Cluster labels from ACM are propagated into the Argo cluster
secrets so ApplicationSet cluster generators can filter target clusters using existing ACM labels.

## Dependencies
  - [OpenShift GitOps Operator](../../operators/gitops/) — the `gitops-operator` policy must be Compliant before the hub policy runs
  - [ManagedServiceAccount](../acm-configs/managedserviceaccount/) — the ManagedServiceAccount add-on must be enabled

## Details
ACM Minimal Version: 2.11

Documentation: [ManagedServiceAccount](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/clusters/index#managed-serviceaccount-addon)

Notes:
  - The example uses an imaginary team named **Scooter**; namespace, resource names, and labels reflect this
  - Two separate policies with different placements are used — one on the hub, one on the team's clusters
  - Hub policy deploys to all clusters via `env-bound-hub-placement`
  - Team ArgoCD instance deploys only to clusters labeled `scooter=enabled` via `ft-scooter--enabled`
  - MSA tokens rotate every 12 hours; cluster secrets are updated automatically on each policy evaluation
  - `ClusterPermission` grants the MSA rights to manage Gatekeeper templates and constraints on managed clusters
  - A dedicated ServiceAccount and ClusterRole are required on the hub for the hub-side template to read MSA token secrets

## Implementation Details
The policy is split into two parts with independent placements:

### Hub policy — `multi-cluster-gitops-hub`
A hub-side template ranges over all `ManagedCluster` resources and for each one creates:

- **`ManagedServiceAccount`** (`scooter-msa-<cluster-name>`) in the cluster's namespace on the hub.
  ACM installs a corresponding ServiceAccount on the managed cluster and populates a token secret on
  the hub, rotating it every 12 hours.
- **`ClusterPermission`** binding the MSA to a ClusterRole that allows full management of Gatekeeper
  templates and constraints (`templates.gatekeeper.sh`, `constraints.gatekeeper.sh`) on the managed cluster.

### Team cluster policy — `multi-cluster-gitops`
Deployed to clusters where the team's ArgoCD instance runs (`ft-scooter--enabled`). Uses a dedicated
hub ServiceAccount (`argo-mulitcluster-hub-serviceaccount`) with read access to `ManagedCluster`,
`ManagedServiceAccount`, and token `Secret` resources. Resources created:

- **Namespace** `argocd-team-scooter`
- **ArgoCD** instance with HA, autoscaling, and RBAC policy granting `argoteam` group org-team role
- **RolloutManager** with HA for progressive delivery
- **ConsoleLink** pointing to the ArgoCD server route
- **Argo cluster Secrets** — one per managed cluster, containing the MSA bearer token, the cluster
  API server URL, and all ACM `ManagedCluster` labels (so ApplicationSet cluster generators can
  filter clusters by existing ACM labels without additional configuration)

### Hub RBAC (`hub-template-auth/`)
A `ServiceAccount`, `ClusterRole`, and `ClusterRoleBinding` deployed as kustomize resources (not
via PolicyGenerator) to grant the hub template engine permission to read MSA token secrets when
rendering the cluster secrets policy.

**To add a managed cluster to the team's ArgoCD:**
```bash
oc label managedcluster <cluster-name> scooter=enabled
```
The cluster secret will be created automatically on the next policy evaluation.
