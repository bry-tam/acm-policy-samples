#  Default Scheduler

## Description
Configures the OpenShift cluster scheduler's `defaultNodeSelector` and applies the node labels
that support it. Standard worker nodes are labeled `bry-tam/worker=` so that pods without an
explicit `nodeSelector` land on them by default. Nodes designated for special workloads are
labeled separately to exclude them from the default pool.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-scheduler-default_nodes-scheduler-about)

Notes:
  - Applied only to clusters labeled `default-scheduler=enabled` via the `ft-default-scheduler--enabled` placement
  - The `Scheduler` CR is applied only after `bry-tam-worker-node-label` is Compliant
  - Nodes are identified by role and exclusion labels; portworx-enabled nodes are skipped from the default pool

## Implementation Details
Three manifests are applied, with the `Scheduler` CR gated on the node labels being in place first:

**`bry-tam-worker-node-label`** — finds all nodes with the `worker` role that do not carry `infra`,
`storage`, or `special-workload` role labels and do not have `portworx=enabled`. Applies the
`bry-tam/worker: ''` label to each matching node. This label is what the `defaultNodeSelector` uses
to attract unscheduled workloads.

**`special-workload-worker-node-label`** — finds worker nodes (excluding infra and storage) that
carry the `isSpecial: "true"` label. For each such node it uses `metadataComplianceType: mustonlyhave`
to set `portworx: enabled` while preserving all other existing labels and removing `bry-tam/worker`.
This pulls special-workload nodes out of the default scheduler pool.

**`cluster-scheduler`** ← depends on `bry-tam-worker-node-label` Compliant — patches the `Scheduler`
singleton to set `defaultNodeSelector: 'bry-tam/worker='`, ensuring pods that do not specify a
`nodeSelector` are scheduled only onto labeled worker nodes.

**To designate a node as a special workload node:**
```bash
oc label node <node-name> isSpecial=true
```
