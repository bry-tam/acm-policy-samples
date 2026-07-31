# Blue/Green MachineConfigPool

Demonstrates how to create blue and green `MachineConfigPool` resources that inherit all
worker `MachineConfig` objects while targeting nodes based on a management-pool label. This
pattern supports blue/green node pool management — for example, draining and replacing one
pool at a time during OS updates or configuration changes.

## How It Works

Each pool sets its `machineConfigSelector` to include both the `worker` role and its own
role (`blue` or `green`). This means:

- All `MachineConfig` objects with `machineconfiguration.openshift.io/role: worker` apply
  to nodes in both pools, keeping them in sync with the base worker configuration
- Pool-specific `MachineConfig` objects can be created with `role: blue` or `role: green`
  to apply changes to only one pool at a time

Nodes are assigned to a pool by setting the label `current-management-pool=blue` or
`current-management-pool=green`. Relabeling a node moves it between pools and triggers
the MCD to reconcile the node to the new pool's rendered config.

## MachineConfigPool Structure

```
machineConfigSelector:
  matchExpressions:
    - {key: machineconfiguration.openshift.io/role, operator: In, values: [worker, blue]}

nodeSelector:
  matchLabels:
    current-management-pool: blue
```

## Assigning Nodes

Label a node to place it in a pool:

```bash
oc label node <node-name> current-management-pool=blue
```

Move a node to the other pool:

```bash
oc label node <node-name> current-management-pool=green --overwrite
```

## Targeting Clusters

Clusters are targeted via the `ft-blue-green-mcp--enabled` placement (clusters labeled
`blue-green-mcp=enabled`).
