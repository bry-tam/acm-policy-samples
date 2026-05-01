#  Cluster Autoscaling

## Description
Configures OpenShift cluster autoscaling using the `ClusterAutoscaler` and `MachineAutoscaler`
resources. The `MachineAutoscaler` is template-driven, reading min and max replica counts from
labels on each `MachineSet`, so no manual configuration is needed when MachineSets are added
or removed.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/machine_management/index#cluster-autoscaler-operator)

Notes:
  - Applied only to clusters labeled `autoscaling=enabled` via the `ft-autoscaling--enabled` placement
  - `MachineAutoscaler` resources are deleted when the policy is removed (`pruneObjectBehavior: DeleteIfCreated`)
  - MachineSets must carry both `autoscale.minreplicas` and `autoscale.maxreplicas` labels to be included

## Implementation Details
**`ClusterAutoscaler`** — a single `default` instance is configured with:
- Max total nodes: 12
- Scale-down enabled with a 10-minute delay after add and 5-minute delay after delete
- `balanceSimilarNodeGroups: true`, ignoring `topology.kubernetes.io/zone` for balance calculations
- `ignoreDaemonsetsUtilization: true` and `skipNodesWithLocalStorage: false`

**`MachineAutoscaler`** — a hub-side template queries all `MachineSet` resources that have both
`autoscale.minreplicas` and `autoscale.maxreplicas` labels set, then generates one `MachineAutoscaler`
per matching `MachineSet`. The min/max values are read directly from the labels, so scaling bounds
are managed by labeling the `MachineSet` rather than editing the policy.

**To enable autoscaling on a MachineSet:**
```bash
oc label machineset <name> -n openshift-machine-api \
  autoscale.minreplicas=1 \
  autoscale.maxreplicas=5
```
