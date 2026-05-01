#  Default Block-All Network Policy

## Description
Ensures every application namespace has a default-deny `NetworkPolicy` that blocks ingress from
other namespaces. Namespaces that need to accept cross-namespace traffic must be explicitly labeled
to opt in. The policy runs in `inform` mode so teams are made aware of missing network isolation
without automatic enforcement.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking/network-policy)

Notes:
  - Deployed to clusters labeled `app-networkpolicies=enabled` via the `ft-app-networkpolicies--enabled` placement
  - Runs as `inform` only — non-compliant namespaces are reported but not automatically remediated
  - System namespaces are excluded: `kube-*`, `openshift*`, `open-*`, `default*`,
    `multicluster-engine`, `hive`, `stackrox`, and any `*-operator` namespace
  - To permit cross-namespace ingress, label the source namespace with
    `policy-group.network.openshift.io/ingress: ""`

## Implementation Details
The `NetworkPolicy` `deny-from-other-namespaces` applies an empty `podSelector` (matching all pods
in the namespace) with a single ingress rule. The rule allows traffic only from namespaces carrying
the label `policy-group.network.openshift.io/ingress: ""`, which is the standard OpenShift network
policy group label used for ingress-controller namespaces and other trusted cross-namespace callers.

**Opting a namespace into allowed cross-namespace ingress:**
```bash
oc label namespace <source-namespace> policy-group.network.openshift.io/ingress=""
```

The `namespaceSelector` in the generator excludes system and operator namespaces from the compliance
check so only application namespaces are evaluated.
