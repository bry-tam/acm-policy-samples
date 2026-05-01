#  ACM ClusterClaims

## Description
Creates `ClusterClaim` resources on each managed cluster that expose cluster metadata as labels
on the `ManagedCluster` object in the hub. The claim values become available for use in placement
predicates and hub-side policy templates via `fromClusterClaim`.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/clusters/index#cluster-claims)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - Claim values are surfaced as `ManagedCluster` labels with the key matching the claim name
  - Claims can be referenced in hub templates with `fromClusterClaim "<claim-name>"`

## Implementation Details
Two claims are configured:

**`install-config-name`** — extracts the cluster name embedded in the API server URL. The URL
format (`https://<name>.<domain>:6443`) is split on `.` and the second segment is taken as the
install-config name. This is useful for correlating the managed cluster with its Hive
`ClusterDeployment` or install-config when the ACM cluster name differs.

**`minor-version`** — reads the full OCP version string from the built-in
`version.openshift.io` cluster claim, splits on `.`, and returns only the `<major>.<minor>`
portion (e.g. `4.16`). This allows placements and templates to target clusters by minor version
without matching on patch-level strings.

**Example use in a placement:**
```yaml
predicates:
  - requiredClusterSelector:
      labelSelector:
        matchLabels:
          minor-version: "4.16"
```

**Example use in a hub template:**
```yaml
value: '{{hub fromClusterClaim "install-config-name" hub}}'
```
