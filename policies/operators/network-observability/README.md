---
# Network Observability Operator

## Description
Deploys the Network Observability Operator and configures a `LokiStack` (backed by ODF NooBaa S3 storage) and a `FlowCollector` to capture and store network flow data for visualization in the OpenShift console.

## Dependencies
  - [Loki Operator](../loki/)
  - [Data Foundation Operator](../data-foundation/) — ODF required for the NooBaa `ObjectBucketClaim` used by LokiStack

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/network_observability/index)

## Implementation Details

**`network-observability-operator`** — creates the `openshift-netobserv-operator` namespace and installs the `OperatorPolicy`.

**`network-observability-configure`** — depends on `network-observability-operator` and `loki-operator`. Copies the NooBaa S3 serving cert `ConfigMap`, creates the `ObjectBucketClaim`, then uses `object-templates-raw` to look up the resulting bucket credentials and build the Loki `Secret`. Deploys `LokiStack` once the secret is ready, waits for Loki health (via `InformOnly` `object-templates-raw` check), then deploys the `FlowCollector` and enables the console plugin.

**`network-observability-status`** — depends on `network-observability-configure`, runs `InformOnly`. Uses `object-templates-raw` to verify the Network Observability operator deployments in `openshift-netobserv-operator` are fully available.
