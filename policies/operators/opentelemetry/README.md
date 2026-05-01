---
# OpenTelemetry Operator

## Description
Deploys the Red Hat build of the OpenTelemetry Operator, which provides the `OpenTelemetryCollector` and `Instrumentation` APIs for collecting, processing, and exporting traces, metrics, and logs. Also creates the `ClusterRole` and `ClusterRoleBinding` needed by the collector. This policy installs the operator only; `OpenTelemetryCollector` instances must be configured per environment.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/red_hat_build_of_opentelemetry/index)

Notes:
  - Does not configure an `OpenTelemetryCollector` instance

## Implementation Details

**`opentelemetry-operator`** — creates the `openshift-opentelemetry-operator` namespace, installs the `OperatorPolicy`, and deploys the `ClusterRole` and `ClusterRoleBinding` required for the collector to read cluster resources.
