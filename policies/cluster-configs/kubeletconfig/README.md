#  KubeletConfig

## Description
Applies custom `KubeletConfig` resources to tune kubelet settings on master and worker node pools.
Currently enables `autoSizingReserved` on both pools so the kubelet automatically calculates and
reserves system resources based on node capacity rather than using static values.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/nodes/index#nodes-nodes-managing-max-pods-proc)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - Applying a `KubeletConfig` triggers a `MachineConfig` rollout on the targeted pool; nodes will drain and reboot sequentially
  - Each `KubeletConfig` targets its pool via `pools.operator.machineconfiguration.openshift.io/<pool>: ""` label selector

## Implementation Details
Two `KubeletConfig` resources are managed, one per node pool:

**`master-kubelet`** — targets the `master` `MachineConfigPool` via the
`pools.operator.machineconfiguration.openshift.io/master: ""` label selector.

**`worker-kubelet`** — targets the `worker` `MachineConfigPool` via the
`pools.operator.machineconfiguration.openshift.io/worker: ""` label selector.

Both set `autoSizingReserved: true`, which instructs the kubelet to dynamically compute
`kubeReserved` memory and CPU based on the node's total allocatable resources. This replaces
the need for static `kubeReserved` values and ensures appropriate headroom is maintained as
node sizes vary across the fleet.
