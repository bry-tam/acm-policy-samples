# ACM Observability Addon Config

## Description
Manages the `multicluster-observability-addon` ClusterManagementAddon on the hub to keep its
global placement's ScrapeConfig references in sync with the `ScrapeConfig` resources deployed
in the `open-cluster-management-observability` namespace.

## Dependencies
  - [ACM Observability](../observability/) — requires the `MultiClusterObservability` stack to be installed

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/observability/index)

Notes:
  - Deployed using the `ft-observability-mcoa--exists` feature-flag placement, which targets any
    cluster where the `observability-mcoa` label is set (any value)
  - The hub cluster must carry the `observability-mcoa` label for this policy to be active
  - When ScrapeConfigs are added or removed from `open-cluster-management-observability`, the
    CMA is automatically reconciled on the next policy evaluation cycle

## Implementation Details
Uses `object-templates-raw` to look up the live `multicluster-observability-addon` CMA and
reconstruct it with `mustonlyhave`, replacing the `global` placement's `scrapeconfigs` config
entries with the ScrapeConfigs currently present in the observability namespace:

- **Non-scrapeconfig config entries** (e.g., `addondeploymentconfigs`) in the global placement
  are preserved verbatim via `toRawJson | toLiteral`
- **Non-global placements** are passed through unchanged using `toRawJson | toLiteral`
- **`addOnMeta`**, **`supportedConfigs`**, and **`rolloutStrategy`** are reflected back from the
  live object to avoid overwriting ACM-managed fields
- **Guard**: if the CMA does not exist (MCOA not installed), the template produces no
  object-templates entries and the policy becomes non-applicable
