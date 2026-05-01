#  Cluster Validations

## Description
Monitors OLM operator lifecycle health and validates cluster security configuration. All checks
run in inform mode — the policy reports non-compliance but does not remediate.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/post-installation_configuration/index)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - `operator-lifecycle-status` runs as `inform` at the policy level; `validate-cluster-security`
    runs as `enforce` at the policy level but its manifest is `InformOnly`, so no remediation occurs
  - The OLM health checks are referenced from Red Hat KCS articles on bundle unpacking failures
    (see `olm/health/readme` for links)

## Implementation Details
**`operator-lifecycle-status`** — three `mustnothave` ConfigurationPolicies scoped to
`openshift-*`, `open-cluster-management`, and `multicluster-engine` namespaces (excluding
`kube-*` and `default`). Each matches a resource in a failed state, so a match means
non-compliance:

  - **`olm-failed-installplan`** — detects `InstallPlan` resources stuck in `Failed` phase
    with `BundleLookupFailed` and `DeadlineExceeded` conditions
  - **`olm-failed-subscription`** — detects `Subscription` resources with `InstallPlanFailed`
    condition and `UpgradePending` state
  - **`olm-failed-job`** — detects `Job` resources in `openshift-marketplace` with a
    `Failed` condition and `DeadlineExceeded` reason, indicating a bundle unpacking failure

**`validate-cluster-security`** — one `InformOnly` ConfigurationPolicy:

  - **`check-fips-enabled`** — uses `object-templates-raw` to iterate master and worker node
    types and check `mustnothave` for `MachineConfig` resources named `99-<type>-fips` with
    `spec.fips: true`, alerting when FIPS mode is configured on the cluster
