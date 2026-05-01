---
# Gatekeeper Operator

## Description
Deploys the Gatekeeper Operator into the `openshift-gatekeeper-operator` namespace and configures a `Gatekeeper` instance with metrics collection and a dynamic sync `ConfigMap`. Includes an `inform`-mode health check for the Gatekeeper deployments and a violation-alerting policy that reports `NonCompliant` whenever any active Gatekeeper constraint has violations.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_management_for_kubernetes/latest/html-single/governance/index#gk-operator-overview)

Notes:
  - Deploys to `openshift-gatekeeper-operator` instead of `openshift-operators` to allow manual InstallPlan approval without conflicts
  - The `SyncConfig` `ConfigMap` is built dynamically from `metadata.gatekeeper.sh/requires-sync-data` annotations on `ConstraintTemplate` objects — add the annotation to any constraint that needs external data synced
  - `Service` and `ServiceMonitor` enable Prometheus scraping of Gatekeeper metrics; no alerting rules are included

## Implementation Details

**`gatekeeper-operator`** — creates the `openshift-gatekeeper-operator` namespace and installs the `OperatorPolicy`.

**`gatekeeper-instance`** — deploys the `Gatekeeper` CR, applies `object-templates-raw` to build a `ConfigMap` containing the union of all `requires-sync-data` annotations found across installed `ConstraintTemplate`s, creates the metrics `Service` and `ServiceMonitor`, and runs an `inform`-mode `object-templates-raw` health check that verifies the `gatekeeper-audit` and `gatekeeper-controller-manager` deployments are fully available.

**`gatekeeper-violations`** — uses `object-templates-raw` to enumerate all `ConstraintTemplate` kinds, look up every `Constraint` instance of each kind, and report `NonCompliant` if any constraint has a non-zero `violations` count. Provides a single ACM policy that surfaces all Gatekeeper policy violations.

### Sync data annotation

Add the following annotation to any `ConstraintTemplate` that requires external data to be synced into the Gatekeeper cache:

```yaml
metadata:
  annotations:
    metadata.gatekeeper.sh/requires-sync-data: |
      "[[{"groups":["example.io"],"versions":["v1"],"kinds":["MyKind"]}]]"
```
