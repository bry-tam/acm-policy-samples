---
# Cluster Logging Operator

## Description
Deploys the Cluster Logging Operator and configures `LokiStack` (backed by ODF S3 storage) and `ClusterLogForwarder` for on-cluster log aggregation. Also provides an optional multi-cluster logging mode where managed clusters forward logs to a centralized Loki instance running on the ACM hub, with per-cluster labels added to each log message.

## Dependencies
  - [Loki Operator](../loki/)
  - [Cluster Observability Operator](../cluster-observability/)
  - [Data Foundation Operator](../data-foundation/) — ODF required for the NooBaa `ObjectBucketClaim` used by LokiStack

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/logging/index)

Notes:
  - Based on Cluster Logging 6.x; see `logs-6.x-migration/` for upgrading from 5.x
  - Deploys `LogFileMetricExporter` on all variants
  - Multi-cluster logging (via `multi-cluster-generator.yml`) is not supported by Red Hat; remove from `kustomization.yaml` if not desired
  - `hub-template-auth/` deploys the `ServiceAccount` and RBAC needed for hub templates to read hub cluster data when building managed-cluster log forwarder config

## Implementation Details

### Standard (on-cluster Loki) — `generator.yml`, placement `ft-logging--loki`

**`cluster-logging-operator`** — depends on `prepare-logging-migration`. Creates the `openshift-logging` namespace, installs the `OperatorPolicy`, and deploys the `ClusterRole`, `ClusterRoleBinding`, and `ServiceAccount` for the log collector.

**`cluster-logging-configure`** — depends on `cluster-logging-operator` and `loki-operator`. Copies the NooBaa S3 serving cert `ConfigMap`, creates the `ObjectBucketClaim`, then uses `object-templates-raw` to look up the bucket credentials and build the Loki `Secret`. Deploys `LokiStack` once the secret is ready, waits for Loki health (via `InformOnly` `object-templates-raw` check), then deploys the `UIPlugin`, `ClusterLogging`, and `LogFileMetricExporter`.

**`logging-operator-status`** — depends on `cluster-logging-configure`, runs `InformOnly`. Uses `object-templates-raw` to verify the log collector `DaemonSet` has a pod on every node.

### Multi-cluster (forward to hub Loki) — `multi-cluster-generator.yml`, placement `ft-logging--multi`

**`multi-cluster-logging-configure`** — depends on `cluster-logging-operator`. Uses `hubTemplateOptions.serviceAccountName: logging-hub-serviceaccount` to read the hub Loki route via a hub-side template, then deploys the collector token `Secret`, `ClusterLogging` forwarder, and `LogFileMetricExporter`.

**`multi-cluster-logging-operator-status`** — depends on `multi-cluster-logging-configure`, runs `InformOnly`. Same node-coverage health check as the standard variant.

### Adding custom labels to log messages

Add an `openshiftLabels` filter to the `ClusterLogForwarder` to attach per-message metadata such as the cluster name:

```yaml
filters:
  - name: ocp-multicluster-labels
    type: openshiftLabels
    openshiftLabels:
      cluster_name: '{{ fromClusterClaim "name" }}'
```

Reference the filter in any pipeline where it should apply:

```yaml
pipelines:
  - name: app-logstore
    outputRefs:
      - otlp-loki-route-app
    inputRefs:
      - application
    filterRefs:
      - ocp-multicluster-labels
```
