---
# Tempo Operator

## Description
Deploys the Tempo Operator (also known as Distributed Tracing Data Collection in the OpenShift documentation), which provides the `TempoStack` and `TempoMonolithic` APIs for storing and querying distributed traces. This policy installs the operator only; a `TempoStack` instance is configured by the Service Mesh policy.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/distributed_tracing/index)

Notes:
  - Does not configure a `TempoStack` instance; the Service Mesh policy deploys the `TempoStack` for mesh tracing

## Implementation Details

**`tempo-operator`** — creates the `openshift-tempo-operator` namespace and installs the `OperatorPolicy`.
