#  Max Dev Workspaces

## Description
Deploys a Gatekeeper `ConstraintTemplate` and `Constraint` that cap the total number of
concurrently active `DevWorkspace` instances on a cluster. When the limit is reached, new
workspace start and create requests are denied at admission time.

## Dependencies
  - [Gatekeeper Operator](../../../operators/gatekeeper/) — the `gatekeeper-instance` policy
    must be Compliant before this policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_dev_spaces/latest)

Notes:
  - Applied to clusters labeled `devspaces=enabled` via `ft-devspaces--enabled`
  - The default maximum is 3 active workspaces; edit `spec.parameters.maxActiveWorkspaces`
    in `maxdevworkspaces.yml` to adjust the limit per environment
  - Gatekeeper must have `DevWorkspace` sync data available; see the sync `Config` in
    [../../../operators/gatekeeper/sync-configmap.yml](../../../operators/gatekeeper/sync-configmap.yml)
  - `informGatekeeperPolicies: false` keeps ACM from wrapping the Gatekeeper resources in
    an additional ConfigurationPolicy audit layer

## Implementation Details
**`maxdevworkspaces-constrainttemplate`** — installs the `MaxDevWorkspaces` `ConstraintTemplate`
with a Rego policy that counts `DevWorkspace` resources in `Running` or `Starting` phase across
all namespaces using Gatekeeper's sync cache. Violations are triggered on `CREATE` when the
total meets or exceeds `maxActiveWorkspaces`, and on `UPDATE` when an inactive workspace is
being started past the limit.

**`max-dev-workspaces`** — installs the `MaxDevWorkspaces` `Constraint` targeting
`workspace.devfile.io/v1alpha2 DevWorkspace` resources with a default limit of 3 active
workspaces. Depends on the `ConstraintTemplate` being deployed first (commented-out
`extraDependencies` block available for stricter ordering if needed).
