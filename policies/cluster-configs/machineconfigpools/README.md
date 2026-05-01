#  MachineConfigPools

## Description
Defines custom `MachineConfigPool` resources for infra and storage node roles. These pools allow
`MachineConfig` and `KubeletConfig` resources to target dedicated node types independently without
affecting the default worker pool. Each pool is deployed independently using its own feature-flag
placement.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/post-installation_configuration/index#post-install-machine-configuration-tasks)

Notes:
  - `infra-machineconfigpool` is applied to clusters labeled `inframachines=enabled` via `ft-inframachines--enabled`
  - `storage-machineconfigpool` is applied to clusters labeled `storage=odf` via `ft-storage--odf`
  - Creating a new `MachineConfigPool` does not by itself reboot nodes; nodes are only rebooted when a `MachineConfig` targeting the pool is applied or changed

## Implementation Details
Two `MachineConfigPool` resources are managed with independent placements:

**`infra` MachineConfigPool** — targets nodes that have the `node-role.kubernetes.io/infra` label
but do not have `node-role.kubernetes.io/storage`. Inherits `MachineConfig` resources from both
the `worker` and `infra` roles via a `matchExpressions` selector on
`machineconfiguration.openshift.io/role`. This ensures infra nodes receive all worker-level
configuration plus any infra-specific overrides.

**`storage` MachineConfigPool** — targets nodes that have both `node-role.kubernetes.io/infra`
and `node-role.kubernetes.io/storage` labels. Inherits `MachineConfig` resources from both the
`worker` and `storage` roles. Storage nodes are expected to carry both role labels, distinguishing
them from pure infra nodes.

**To assign a node to the infra pool:**
```bash
oc label node <node-name> node-role.kubernetes.io/infra=""
```

**To assign a node to the storage pool:**
```bash
oc label node <node-name> node-role.kubernetes.io/infra="" node-role.kubernetes.io/storage=""
```
