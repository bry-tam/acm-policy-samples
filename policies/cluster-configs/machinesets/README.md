#  MachineSets

## Description
Creates dedicated `MachineSet` resources for infra and storage node roles, scaling out nodes
beyond the default worker pool for workload isolation.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#machinesets-intro)

Notes:
  - `infra-machineset` is applied to clusters labeled `inframachines=enabled` via `ft-inframachines--enabled`
  - `storage-machineset` is applied to clusters labeled `storage=odf` via `ft-storage--odf`
  - Both policies are AWS-specific; the template reads region and infrastructure ID from the cluster `Infrastructure` object

## Implementation Details
**`infra-machineset`** — creates one `MachineSet` per availability zone (a, b, c) in the cluster's
AWS region. The template reads the cluster `Infrastructure` object to determine the region and
infrastructure ID, then copies and merges the `providerSpec` from an existing worker `MachineSet`
as a baseline. Each infra `MachineSet` uses:
  - Instance type: `c6i.8xlarge`
  - Root volume: 200 GiB `io1` encrypted EBS
  - Node label: `node-role.kubernetes.io/infra: ""`
  - Taint: `node-role.kubernetes.io/infra: NoSchedule`

**`storage-machineset`** — follows the same template pattern as the infra `MachineSet` but uses the
`storage` role. Storage nodes carry both the infra and storage role labels so they receive infra
`MachineConfig` resources and are excluded from the infra `MachineConfigPool`. Each storage
`MachineSet` uses:
  - Instance type: `c6i.8xlarge`
  - Root volume: 200 GiB `io1` encrypted EBS
  - Node labels: `node-role.kubernetes.io/infra: ""`, `node-role.kubernetes.io/storage: ""`,
    `cluster.ocs.openshift.io/openshift-storage: ""`
  - Taint: `node.ocs.openshift.io/storage: NoSchedule`
