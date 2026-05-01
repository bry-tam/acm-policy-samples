---
# Kiali Operator

## Description
Deploys the Kiali Operator, which provides the `Kiali` API for visualizing service mesh topology, traffic flow, and health. This policy installs the operator only; a `Kiali` instance is configured by the Service Mesh operator when OSSM is deployed.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/latest/html-single/observability/index#kiali-operator-provided-by-red-hat)

Notes:
  - Does not configure a `Kiali` CR; the Service Mesh policy creates the Kiali instance as part of the mesh control plane

## Implementation Details

**`kiali-operator`** — creates the `openshift-operators` namespace entry and installs the `OperatorPolicy`.
