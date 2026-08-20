# copy-cudn-nads

## Description
Creates additional `NetworkAttachmentDefinition` copies for each `ClusterUserDefinedNetwork` that carries the `cnv/multiple-nad` label. The label value is an integer specifying how many copies to produce. Each copy is named `<source-nad-name>-<index>` (1-based) and has its embedded JSON config updated so that `name` and `netAttachDefName` reflect the new NAD name.

This is useful for OpenShift Virtualization workloads where multiple VMs in the same namespace each need a dedicated interface on the same CUDN-backed network — Multus requires one NAD per attachment, so you need N distinct NADs for N simultaneous attachments.

## Dependencies
- A policy or manual step that creates the `ClusterUserDefinedNetwork` resources so that OVN-Kubernetes can auto-generate the source NAD in each opted-in namespace.

## Details
ACM Minimal Version: 2.12
Documentation: https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/2.12/html/governance/governance#template-functions

Notes:
  - Source NADs are discovered via a single cluster-scoped lookup of all NADs carrying the `k8s.ovn.org/user-defined-network` label. OVN-Kubernetes sets this label on every NAD it creates from a CUDN; the label value is always empty — it is a presence-only marker.
  - CUDNs are matched to their NADs via `metadata.ownerReferences` (kind `ClusterUserDefinedNetwork`, name == CUDN name), not by label value.
  - The policy creates copies in the same namespace as each source NAD. If a CUDN is opted into multiple namespaces, copies are created in each namespace independently.
  - The `spec.config` JSON is parsed, `name` and `netAttachDefName` are replaced for each copy, and the JSON is re-serialised. All other CNI config fields (type, topology, MTU, VLAN, physicalNetworkName, etc.) are carried over unchanged.
  - The `netAttachDefName` field follows the Multus convention `<namespace>/<nad-name>`.
  - Copies do **not** receive the `k8s.ovn.org/user-defined-network` label or an `ownerReference`, so OVN-Kubernetes does not attempt to reconcile them.
  - The linter (`--lint`) reports a false-positive `unusedVariables` warning for the `$cudn_owners` list. The variable is genuinely used by `has` inside the `if not` guard — the linter does not recognise function-argument position as a read in this context. The template resolves correctly.

## Implementation details (Optional)

### How the template works

```
Build NAD index: lookup all NADs with label k8s.ovn.org/user-defined-network
  For each NAD, add to $cudn_owners list keyed by ownerRef CUDN name

For each CUDN with label cnv/multiple-nad:
  copyCount = label value as int

  For each NAD whose ownerReferences contains this CUDN:
    config = fromJson(nad.spec.config)

    For i in 0 .. copyCount-1:
      newName = <nad-name>-<i+1>
      config.name          = newName
      config.netAttachDefName = <namespace>/<newName>
      emit NAD objectDefinition
```

### Labeling the CUDN

Add the `cnv/multiple-nad` label to a CUDN to enable copy generation:

```yaml
metadata:
  name: vm-data-vlan200
  labels:
    cnv/multiple-nad: "3"   # creates copies -1, -2, -3
```

### Source NAD structure (as created by OVN-Kubernetes)

OVN-Kubernetes auto-creates a NAD like the following in each opted-in namespace when a CUDN is provisioned:

```yaml
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: vm-data-vlan200
  namespace: my-vm-namespace
  labels:
    k8s.ovn.org/user-defined-network: ""   # presence marker only; value is always empty
  ownerReferences:
    - apiVersion: k8s.ovn.org/v1
      kind: ClusterUserDefinedNetwork
      name: vm-data-vlan200
spec:
  config: |
    {
      "cniVersion": "1.0.0",
      "name": "cluster_udn_vm-data-vlan200",
      "type": "ovn-k8s-cni-overlay",
      "topology": "localnet",
      "netAttachDefName": "my-vm-namespace/vm-data-vlan200",
      "physicalNetworkName": "localnet-vm-data-vlan200",
      "role": "secondary",
      "mtu": 1500
    }
```

### Generated NADs (copyCount=3)

The policy enforces these three NADs in `my-vm-namespace`:

```
vm-data-vlan200-1  →  config.name=vm-data-vlan200-1  netAttachDefName=my-vm-namespace/vm-data-vlan200-1
vm-data-vlan200-2  →  config.name=vm-data-vlan200-2  netAttachDefName=my-vm-namespace/vm-data-vlan200-2
vm-data-vlan200-3  →  config.name=vm-data-vlan200-3  netAttachDefName=my-vm-namespace/vm-data-vlan200-3
```

All other config fields (`type`, `topology`, `physicalNetworkName`, `role`, `mtu`, etc.) are identical to the source NAD.

### Using copies in a VirtualMachine

Reference each copy as a separate Multus network in a `VirtualMachine` spec:

```yaml
spec:
  template:
    spec:
      networks:
        - name: nic1
          multus:
            networkName: my-vm-namespace/vm-data-vlan200-1
        - name: nic2
          multus:
            networkName: my-vm-namespace/vm-data-vlan200-2
```
