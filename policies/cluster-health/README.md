#  Cluster Health

## Description
Validates the OCP cluster is healthy by checking cluster version, ClusterOperators,
MachineConfigPools, and node status. All checks are `InformOnly` — the policy reports
non-compliance but does not remediate.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/post-installation_configuration/index)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - All four ConfigurationPolicies run in `InformOnly` mode; violations surface as policy
    non-compliance rather than triggering any remediation
  - EUS (Extended Update Support) channels are handled specially: MCPs and nodes are allowed to
    be paused on odd-numbered minor releases during an EUS upgrade path

## Implementation Details
The single policy `cluster-health-eval` contains four `InformOnly` ConfigurationPolicies,
each driven by `object-templates-raw` templates that loop over live cluster resources:

**`cluster-version-status`** — reads the `ClusterVersion` object to determine the desired or
in-progress target version (`spec.desiredUpdate.version` falling back to
`status.desired.version`). Checks that the version appears in `status.history` with state
`Completed` and that the `Available` condition is `True` with `Failing` and `Progressing`
both `False`.

**`cluster-operator-status`** — iterates all `ClusterOperator` resources, skipping a
configurable exclusion list (currently `aro` and `cert-manager`). For each operator, checks
that `Progressing` and `Degraded` are `False`, `Available` is `True`, and the operator version
matches the desired cluster version.

**`machine-config-pool-status`** — iterates all `MachineConfigPool` resources. Detects
EUS upgrade pausing: the `master` MCP is never allowed to be paused; worker and custom MCPs
may be paused on odd-numbered releases when the channel starts with `eus`. For non-paused pools,
checks that `Updated` is `True`, `Updating` and `Degraded` are `False`, and
`readyMachineCount` equals `machineCount`. For EUS-paused pools, only checks that degraded
and unavailable counts are zero.

**`node-status`** — iterates all nodes and matches each to its MachineConfigPool using the
MCP's `nodeSelector` (supports both `matchLabels` and `matchExpressions`). Nodes matched by
non-worker MCPs are verified first; remaining nodes fall back to the worker MCP's rendered
config. For each node, checks that `currentConfig` and `desiredConfig` annotations match the
MCP's rendered config name, `state` is `Done`, and all pressure conditions are `False` with
`Ready` `True`.
