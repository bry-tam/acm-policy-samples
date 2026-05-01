#  ACM Policy Prometheus Alerts

## Description
Creates a `PrometheusRule` on the hub that fires a `critical` alert for every ACM governance policy
that is non-compliant. Provides a simple, direct alternative to PolicyReport-based alerting.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: None

Notes:
  - Deployed to hub using the `ft-acm-hub--active` feature-flag placement
  - Requires the `open-cluster-management` namespace to have the `openshift.io/cluster-monitoring: 'true'` label
  - Alert fires after a policy has been non-compliant for 2 minutes
  - Templates are disabled on this policy (`disable-templates: "true"`) to avoid interpreting
    Prometheus expression syntax as ACM template expressions

## Implementation Details
The policy creates two resources:

**Namespace** — ensures `open-cluster-management` exists with `openshift.io/cluster-monitoring: 'true'`
so Prometheus scrapes the namespace for ACM metrics.

**PrometheusRule** — defines a `GovernanceNotCompliant` alert group with a single rule:

```
expr: policy_governance_info{type="root"} > 0
for: 2m
severity: critical
```

The `policy_governance_info` metric is exposed by ACM's governance framework. A value greater than
zero for a root policy indicates at least one managed cluster is non-compliant. The alert message
includes the policy namespace and name from the metric labels.
