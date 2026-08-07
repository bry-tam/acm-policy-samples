---
# Advanced Cluster Security Operator

## Description
Deploys ACS, creating a `Central` instance on the hub and a `SecuredCluster` on every
`acs`-labeled cluster (hub included). Fully manages the init-bundle lifecycle,
automatically rotating certificates before they expire.

Split into three independent `PolicyGenerator`s so each concern can be read on its own:

| Directory | Deploys to | Description |
|---|---|---|
| [`operator/`](./operator/) | Any cluster labeled `acs` | Installs the RHACS operator and namespaces |
| [`central/`](./central/) | Hub only | `Central` CR, health check, init-bundle lifecycle, cert rotation |
| [`sensor/`](./sensor/) | Any cluster labeled `acs` | Propagates certs and creates `SecuredCluster` |

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest)

Notes:
  - A single feature-flag label, `acs` (any value, e.g. `hub` or `managed`), controls
    which clusters get the operator and sensor. `central` is always hub-only regardless
    of the label's value.
  - See each subdirectory's README for implementation details.
