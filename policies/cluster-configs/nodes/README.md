#  Node Configuration

## Description
Applies base node-level configuration via `MachineConfig` resources, covering cgroup version
and CRI-O runtime settings.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/post-installation_configuration/index#post-install-machine-configuration-tasks)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - Changing either resource triggers a MachineConfig rollout, which will drain and reboot nodes one at a time

## Implementation Details
**`node-cgroups`** — sets the cluster-wide `cgroupMode` to `v2` on the `Node` cluster config
object. This enables cgroup v2 for all workloads and is required by some newer OpenShift features.

**`node-crio-runtime`** — applies a `ContainerRuntimeConfig` targeting all built-in
`MachineConfigPool` resources (via `machineconfiguration.openshift.io/mco-built-in: Exists`
selector) to set the CRI-O default runtime to `crun` instead of `runc`.
