#  Multicluster CoreDNS Service Data

## Description
Aggregates CoreDNS service endpoints from managed clusters participating in service mesh
federation and distributes the resulting DNS configuration to all clusters. Two policies work
together: a hub-side policy that collects service data via `ManagedClusterView`, and a
managed-cluster-side policy that enforces the resulting CoreDNS `Secret` using hub-side
template expansion. Designed for use with Kuadrant multicluster DNS federation.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/governance/index#hub-templates)

Notes:
  - `coredns-service-data` is applied to the hub only via `env-bound-hub-placement`
  - `coredns-secret` is applied to all clusters via `env-bound-placement`, using
    `hubTemplateOptions.serviceAccountName: multicluster-hub-serviceaccount` to authorize
    the hub template to read `ManagedClusterView` status
  - The hub-template ServiceAccount, ClusterRole, and ClusterRoleBinding are deployed as
    plain kustomize resources from `hub-template-auth/` (not through the PolicyGenerator)
  - Only clusters labeled `servicemesh-federation=enabled` have `ManagedClusterView`
    resources created; clusters without that label are excluded from the DNS server list

## Implementation Details
**`coredns-service-managedclusterview`** — runs on the hub and uses a managed-cluster-side
`object-templates-raw` template to iterate all `ManagedCluster` resources labeled
`servicemesh-federation=enabled`. For each matching cluster it enforces a `ManagedClusterView`
in that cluster's namespace, scoped to the `coredns` `Service` in `openshift-dns`. The MCVs
are labeled `coredns-service: ""` for discovery by the hub template in the next policy.

**`coredns-service-data-secret`** — runs on all managed clusters and uses a hub-side
`object-templates-raw` template to collect results from all `ManagedClusterView` resources
labeled `coredns-service`. For each MCV it extracts the LoadBalancer ingress hostname and
appends `:53` to build the nameserver list. It then enforces a `Secret` named `core-dns` in
the `kuadrant-coredns` namespace with:
  - `NAMESERVERS` — base64-encoded comma-joined list of `hostname:53` entries from all MCVs
  - `ZONES` — base64-encoded wildcard zone string derived from the cluster's `Ingress` domain
    (`*.global.<cluster-ingress-domain>`)

**`hub-template-auth/`** — plain kustomize resources (not policy-managed) that grant the
`multicluster-hub-serviceaccount` in `bry-tam-policies` read access to
`ManagedClusterView` resources via a `ClusterRole` and `ClusterRoleBinding`. This ServiceAccount
is referenced by `hubTemplateOptions` to authorize the hub template lookup of MCV status.
