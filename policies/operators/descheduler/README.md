---
# Descheduler Operator

## Description
Installs the Kube Descheduler operator and configures a `KubeDescheduler` instance with the
`KubeVirtRelieveAndMigrate` profile, which evicts VM pods from overutilized nodes to allow
KubeVirt to live-migrate them to more appropriate nodes. Eviction concurrency limits are
dynamically sourced from the cluster's `HyperConverged` live migration configuration.

## Dependencies
- [OpenShift Virtualization](../virtualization/) — the `HyperConverged` CR in `openshift-cnv`
  is used to derive eviction limits; the descheduler will still deploy with KubeVirt defaults
  if the CR is absent or has no `liveMigrationConfig` set

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/nodes/evicting-pods-using-the-descheduler)

Notes:
  - Targets clusters labeled `descheduler=enabled` via the `ft-descheduler--enabled` placement
  - Uses `upgradeApproval: Automatic` — pin `startingCSV` and `versions` to lock to a specific release
  - `KubeDescheduler` depends on the `OperatorPolicy` being Compliant before it is applied
  - `KubeVirtRelieveAndMigrate` and `LongLifecycle`/`LifecycleAndUtilization` profiles are
    mutually exclusive — do not combine them

## Implementation Details
Three resources are deployed within the single `descheduler-operator` policy:

**OperatorPolicy** (`descheduler-operator-install`) — installs the operator via OLM into
`openshift-kube-descheduler-operator` with cluster monitoring enabled.

**KubeDescheduler** (`descheduler-kubevirt-migrate`) — depends on the OperatorPolicy being
Compliant; uses `object-templates-raw` to look up the `HyperConverged` CR and map its
`liveMigrationConfig` fields to `evictionLimits`:

| `evictionLimits` field | Source field | Default |
|---|---|---|
| `total` | `parallelMigrationsPerCluster` | 5 |
| `node` | `parallelOutboundMigrationsPerNode` | 2 |

The defaults match KubeVirt's built-in defaults and are applied via `dig` fallback when the
HyperConverged CR does not explicitly set those values.

**MachineConfig** (`99-worker-psi-kernelarg`) — adds the `psi=1` kernel argument to worker
nodes, enabling Pressure Stall Information (PSI) metrics required by the
`DevKubeVirtRelieveAndMigrate` CPU/PSI utilization profile.
