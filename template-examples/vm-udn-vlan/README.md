#  VM UDN VLAN

## Description
Demonstrates how to use ACM policies alongside `ClusterUserDefinedNetwork` (CUDN) resources to configure the node-level OVN bridge mappings and per-namespace primary `UserDefinedNetwork` instances needed to run OpenShift Virtualization VMs on a VLAN-backed secondary network.

The policy uses managed-cluster-side templates to discover every Localnet `ClusterUserDefinedNetwork` on the cluster at evaluation time. For each Localnet CUDN it creates an NMState `NodeNetworkConfigurationPolicy` to wire the OVN bridge mapping on worker nodes, then creates a primary `UserDefinedNetwork` in every namespace that is already opted in to the CUDN.

## Files

| File | Purpose |
|------|---------|
| `clusteruserdefinednetwork.yml` | Example CUDN — Localnet secondary network, VLAN 200, physical network `localnet-2`, IPAM disabled |
| `cudn-localnet-vlan.yml` | `object-templates-raw` template that creates the NNCP and UDN resources for each Localnet CUDN |
| `generator.yml` | PolicyGenerator definition |
| `kustomization.yaml` | Kustomize entry point |

## How It Works

### ClusterUserDefinedNetwork
A CUDN defines a cluster-scoped network and selects participating namespaces via `spec.namespaceSelector`. For Localnet topology, the CUDN bridges an OVN logical network to a physical network (identified by `physicalNetworkName`) on each node. OVN-Kubernetes requires the node to have a bridge mapping between the logical localnet name and a local OVS bridge.

```
CUDN (example-vlan-200)  topology: Localnet
  physicalNetworkName: localnet-2
  vlan.access.id: 200
        │
        ├─► NNCP: vmdata-localnet-200
        │     OVN bridge mapping: localnet-2 → br-vmdata
        │     Applied to all worker nodes
        │
        └─► namespaceSelector: cudn-vmdata-vlan=example-vlan-200
              │  + k8s.ovn.org/primary-user-defined-network (must already exist)
              ▼
          Matching namespaces
              │
              └─► UserDefinedNetwork: example-vlan-200-udn-primary
                    topology: Layer2, role: Primary
                    subnet: 192.168.0.0/24
```

### Policy Template Logic
`cudn-localnet-vlan.yml` uses `object-templates-raw` with managed-cluster templates (`{{ }}`) evaluated on the managed cluster:

1. `lookup "k8s.ovn.org/v1" "ClusterUserDefinedNetwork"` — discovers all CUDNs; skips any where `spec.network.topology` is not `Localnet`
2. Builds a Kubernetes label selector string for namespace lookup:
   - Seeds the selector with `k8s.ovn.org/primary-user-defined-network` so only already opted-in namespaces are matched
   - **`matchLabels`**: each entry appended as `key=value`
   - **`matchExpressions`**: `Exists` → `key`; `DoesNotExist` → `!key`; `In`/`NotIn` → `key in (val1,val2)`
   - All terms joined with commas
3. Emits a `NodeNetworkConfigurationPolicy` named `vmdata-localnet-<vlan-id>` targeting worker nodes, mapping `spec.network.localnet.physicalNetworkName` → `br-vmdata` in OVN
4. Passes the selector string to `lookup "v1" "Namespace"` so the API server returns only opted-in namespaces
5. For each matching namespace, emits a `UserDefinedNetwork` named `<cudn-name>-udn-primary` with Layer2 topology, Primary role, and subnet `192.168.0.0/24`

### Namespace Opt-in
Namespaces are matched only when they already carry `k8s.ovn.org/primary-user-defined-network` (plus any labels from the CUDN's `namespaceSelector`). This label must be applied to a namespace before the policy will create a `UserDefinedNetwork` in it.

## Adapting This Example

- **Different placement**: Replace `env-bound-nohub-placement` in `generator.yml` with a feature-flag placement (e.g., `ft-openshift-virtualization--enabled`) to target only clusters running OpenShift Virtualization.
- **Different subnet per CUDN**: Replace the hardcoded `192.168.0.0/24` with a value read from a hub-side ConfigMap keyed by CUDN name.
- **Different bridge**: Replace `br-vmdata` in `cudn-localnet-vlan.yml` with the OVS bridge name used in your environment.
- **Deploy the CUDN via policy**: Add `clusteruserdefinednetwork.yml` as a second manifest in `generator.yml` to enforce the CUDN itself alongside the NNCP and UDN resources.
