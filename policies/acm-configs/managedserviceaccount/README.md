#  ManagedServiceAccount

## Description
Enables the ManagedServiceAccount add-on in MultiClusterEngine and installs the
`managed-serviceaccount` `ManagedClusterAddOn` on every managed cluster. ManagedServiceAccount
allows the hub to create and manage ServiceAccounts on managed clusters and retrieve their tokens.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.13/html-single/clusters/index#managed-serviceaccount-addon)

Notes:
  - Deployed to hub using the `ft-acm-hub--active` feature-flag placement
  - Requires the `managedserviceaccount` component to be enabled in `MultiClusterEngine`
  - Addon is installed into `open-cluster-management-agent-addon` on each managed cluster

## Implementation Details
The policy manages two resources:

**MultiClusterEngine patch** — enables the `managedserviceaccount` component in the `multiclusterengine`
singleton, which makes the add-on available cluster-wide.

**ManagedClusterAddOn** — a hub-side template ranges over all `ManagedCluster` resources and creates
a `managed-serviceaccount` `ManagedClusterAddOn` in each cluster's namespace on the hub. ACM uses this
object to install and manage the add-on agent on the corresponding managed cluster.
