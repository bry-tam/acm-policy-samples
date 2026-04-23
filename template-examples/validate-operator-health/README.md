# Validate Operator Health

Demonstrates how to write ACM ConfigurationPolicies that validate an OLM-managed operator
is installed and healthy. Uses the Compliance Operator as the concrete example target.

All checks use `remediationAction: InformOnly` — health checks should observe, not remediate.

A ConfigMap (`operator-versions-cm.yml`) is deployed to the `bry-tam-policies` namespace as
a separate kustomize resource (not through the generator) and acts as the source of truth for
expected operator versions. Keys are operator package names; values are expected version strings.
Updating the ConfigMap updates the enforced baseline without regenerating policies.

## Checks

### 1. Subscription State (`subscription-check.yml`)

Ranges over all Subscriptions in `openshift-compliance` and finds the one whose `spec.name`
matches the operator package name. Searching by `spec.name` rather than `metadata.name` is
more reliable — the Subscription name is not guaranteed to match the package name.

Validates:

- **Correct spec** — `channel`, `name`, `source`, and `sourceNamespace` match expected values
- **`status.state: AtLatestKnown`** — OLM has confirmed the latest CSV in the channel is
  installed with no pending upgrades or installation errors

Uses `fail` with a descriptive message if no matching Subscription is found.

### 2. CSV Version and Phase (`csv-version-check.yml`)

Uses the same Subscription lookup to retrieve `status.installedCSV` — the CSV confirmed
fully installed — then looks up that ClusterServiceVersion and validates:

- **`spec.version`** matches the value for the operator key in the `operator-versions` ConfigMap,
  read via a hub-side template (`{{hub fromConfigMap ... hub}}`). The hub evaluates this before
  distributing the policy, so managed clusters receive the resolved string.
- **`status.phase: Succeeded`** — the CSV has fully reconciled with no errors

`installedCSV` is used here (rather than `currentCSV`) because it reflects what is confirmed
running, making the version and phase checks meaningful even during an in-progress upgrade.

### 3. Deployment Health (`deployment-health.yml`)

Uses the same Subscription lookup to retrieve `status.currentCSV`, then looks up that
ClusterServiceVersion and ranges over `spec.install.spec.deployments` — the authoritative
list of deployments the operator declared it would create. This scopes the check to exactly
what the operator owns rather than everything in the namespace.

For each declared deployment, validates:

- `replicas`, `updatedReplicas`, `readyReplicas`, and `availableReplicas` all match the
  desired count from the live Deployment spec
- All deployment conditions have `status: True`
- Label `olm.owner` equals `currentCSV` — OLM stamps this on every resource it manages;
  a missing or mismatched value indicates the deployment is not under OLM control

`currentCSV` is used here because OLM stamps `olm.owner` with `currentCSV` at the time it
creates the deployment. Uses `fail` if the CSV declares no deployments.

### currentCSV vs installedCSV

During a steady state (no upgrade in progress) these are equal. During an upgrade,
`currentCSV` advances to the new target version as soon as OLM resolves it from the catalog,
while `installedCSV` stays on the previous version until the new CSV reaches `Succeeded`.
The version/phase check uses `installedCSV` (confirmed running); the deployment label check
uses `currentCSV` (matches what OLM stamped at creation time).

## Adapting for Other Operators

Change the following to target a different operator:

| What to change | Where |
|---|---|
| `$operatorName` value | all three manifest files |
| Subscription `namespace` in the lookup | all three manifest files |
| `spec.channel`, `spec.source`, `spec.sourceNamespace` | `subscription-check.yml` |
| Operator key and version in the ConfigMap | `operator-versions-cm.yml` |
| `fromConfigMap` key argument | `csv-version-check.yml` |
| `placement.placementName` | `generator.yml` |
| `dependencies[].name` | `generator.yml` (point at the operator's install policy) |
