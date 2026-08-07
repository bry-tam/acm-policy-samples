---
# ACS Operator

## Description
Installs the RHACS operator (`rhacs-operator` namespace and `OperatorPolicy`) and creates
the `stackrox` namespace. Deployed to any cluster carrying the `acs` label, hub or
managed, since both roles need the operator running.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest)

Notes:
  - Bound to the `ft-acs--exists` placement — any `ManagedCluster` with an `acs` label,
    regardless of value (`hub` or `managed`)
  - See [`../central/`](../central/) for hub-only Central lifecycle management and
    [`../sensor/`](../sensor/) for sensor/`SecuredCluster` deployment

## Implementation Details
Single policy, `acs-operator`, bundles the two namespaces and the `OperatorPolicy` together
since they have no ordering requirements between them.
