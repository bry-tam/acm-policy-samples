# VLAN Bond NodeNetworkConfigurationPolicy

Demonstrates how to use ACM hub-side ConfigMaps to drive per-node NMState
`NodeNetworkConfigurationPolicy` (NNCP) generation across a cluster. Each worker node
is configured individually based on its entry in a cluster-specific ConfigMap, allowing
heterogeneous network layouts within the same cluster.

## How It Works

A ConfigMap named after the `ManagedCluster` is copied to the managed cluster's `default`
namespace via the `copy-configmap` policy manifest. The NNCP template then reads that
ConfigMap, iterates over all worker nodes, and generates one NNCP per `nodeNetworks` entry
for each node that has a matching key in the ConfigMap. Nodes not listed in the ConfigMap
are skipped.

Each NNCP is named `<network-name>-<node-name>` and scoped to that node via
`spec.nodeSelector.kubernetes.io/hostname`.

## ConfigMap Structure

The ConfigMap lives in the `acm-policies` namespace on the hub (see `example-configmap.yml`).
Each key is a node name; the value is a YAML document with a `nodeNetworks` list:

```yaml
data:
  NODE01: |
    nodeNetworks:
      - name: <nncp-name-prefix>
        mtu: 9000                     # optional, defaults to 1500
        ethernets:
          - name: <logical-name>
            macAddress: "<mac>"
          - name: <logical-name>
            macAddress: "<mac>"
        bonds:
          - name: <bond-name>
            mode: "<bond-mode>"       # e.g. active-backup, 802.3ad
        vlans:                        # optional
          - id: <vlan-id>
            address:
              - ip: <ip>
                prefix-length: <cidr>
        bridges:                      # optional
          - name: <bridge-name>
            type: <bridge-type>       # linux-bridge or ovs-bridge
```

Multiple `nodeNetworks` entries per node are supported — each produces a separate NNCP.

## Generated Interfaces

For each `nodeNetworks` entry the following interfaces are always created:

| Interface | Type | Details |
|---|---|---|
| Physical ports | `ethernet` | Identified by MAC address; avoids reliance on interface naming |
| Bond | `bond` | Aggregates all ethernet ports using the specified mode |

The following are created conditionally:

| Interface | Condition | Details |
|---|---|---|
| VLAN | `vlans` key present | Tagged sub-interface on the bond with a static IPv4 address |
| Bridge | `bridges` key present | Attaches the bond as its port; STP disabled |

### Bridge Types

- **`linux-bridge`** — standard kernel bridge; no extra options
- **`ovs-bridge`** — Open vSwitch bridge; additionally sets `allow-extra-patch-ports: true`
  to permit OVS patch port connections (required for OVN-Kubernetes and similar CNIs)

## Example Configmap Nodes

| Node | Networks configured |
|---|---|
| NODE01 | Bond + VLAN 40 with static IP |
| NODE02 | Bond + VLAN 40 with static IP; Bond + OVS bridge (`br-vm-data`) |
| NODE03–10 | Bond + VLAN 40 with static IP |
