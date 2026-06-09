# Per-Cluster Data

Demonstrates how to store cluster-specific configuration in hub-side ConfigMaps and use it
to drive managed-cluster resource generation via ACM hub templates. Each ConfigMap is named
after the `ManagedCluster` it configures, and each key within it matches the name of the
policy that reads it — allowing multiple policies to share a single ConfigMap without
collisions.

## How It Works

A hub-side ConfigMap is created for each cluster. The policy reads it using:

```
fromConfigMap "" .ManagedClusterName .PolicyMetadata.name | fromYaml
```

- **ConfigMap name** — `.ManagedClusterName`: the managed cluster's name (e.g. `local-cluster`)
- **ConfigMap namespace** — `""`: resolves to the policy's namespace (e.g. `bry-tam-policies-prod`)
- **ConfigMap key** — `.PolicyMetadata.name`: the name of the policy reading it (e.g. `machinesets`)

The value stored under that key is a YAML document. The hub template parses it and uses the
result to drive the managed-cluster template — embedding resolved values as literals in the
template string sent to the spoke.

## MachineSet Example

`machinesets.yml` shows how to combine hub-side ConfigMap data with managed-cluster-side
API lookups to create `MachineSet` resources across multiple availability zones.

**Hub-side** (resolved once per cluster at policy generation time):
- Reads the machineset list from the cluster's ConfigMap
- Iterates over each machineset definition and each availability zone suffix
- Embeds instance type, volume size, replicas, labels, taints, and zone suffix as literals

**Managed-side** (evaluated on the spoke cluster):
- Looks up the `Infrastructure` CR to get the cluster's region and infrastructure ID
- Looks up an existing worker `MachineSet` to inherit common providerSpec fields
- Constructs the full zone name (`region + az suffix`) and providerSpec via `printf` and `merge`

One `MachineSet` object is created per machineset definition per availability zone.

## ConfigMap Structure

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: <cluster-name>
  namespace: bry-tam-policies-prod
data:
  machinesets: |
    - baseName: <string>           # appended to the infrastructure ID in the MachineSet name
      replicas: <int>              # replicas per availability zone
      instanceType: <string>       # EC2 instance type
      volumeSize: <int>            # root EBS volume size in GiB
      role: <string>               # sets machine-role labels and node-role.kubernetes.io/<role>
      availabilityZones:           # AZ suffix letters; region is read from the Infrastructure CR
        - a
        - b
        - c
      labels:                      # optional: additional node labels
        <key>: "<value>"
      taints:                      # optional: node taints
        - key: <string>
          effect: <NoSchedule|NoExecute|PreferNoSchedule>
          value: "<string>"        # optional
```

See `cm-machinesets.yml` for a complete example with infra, storage, and general-purpose
machineset definitions.

## Existing Examples

| File | Description |
|---|---|
| `cm-cluster-monitoring-config.yaml` | Snippets showing scalar and complex-object ConfigMap values used by a MachineSet and a LokiStack policy |
| `cm-machinesets.yml` | Example hub ConfigMap for `local-cluster` with three machineset families |
| `machinesets.yml` | Policy manifest implementing the machineset template |
| `generator.yml` | PolicyGenerator targeting clusters labeled `per-cluster-machinesets=enabled` |
