---
# OpenShift Service Mesh Operator

## Description
Deploys the OpenShift Service Mesh 3.x Operator and configures a cluster-wide Istio control plane with IstioD, Istio CNI, Kiali, Tempo distributed tracing (backed by ODF S3 storage), OpenTelemetry collection, metrics monitoring, and a dedicated ingress gateway namespace.

## Dependencies
  - [Kiali Operator](../kiali/)
  - [OpenTelemetry Operator](../opentelemetry/)
  - [Tempo Operator](../tempo/)
  - [Cluster Observability Operator](../cluster-observability/)
  - [Data Foundation Operator](../data-foundation/) — ODF required for the NooBaa `ObjectBucketClaim` used by TempoStack

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/latest)

Notes:
  - Configures Istio with cluster-wide mode using `IstioRevisionTag` for transparent injection
  - Tempo tracing runs in the `tracing-system` namespace using ODF S3 via NooBaa
  - Ingress gateway runs as a standalone `Deployment` in the `istio-ingress` namespace
  - Health check for Service Mesh is not yet implemented

## Implementation Details

**`servicemesh-operator`** — creates the `openshift-operators` namespace entry and installs the `OperatorPolicy`.

**`servicemesh-controlplane`** — depends on `servicemesh-operator`, `kiali-operator`, `opentelemetry-operator`, `tempo-operator`, and `odf-operator-status`. Deploys in sequence:
  - Istio control plane: `istio-system` and `istio-cni` namespaces, `Istio` CR, `IstioCNI` CR, and `IstioRevisionTag` to set the default revision
  - Tracing stack (`tracing-system` namespace): Tempo RBAC roles, `OpenTelemetryCollector`, `ObjectBucketClaim` for S3 storage, `object-templates-raw` to build the `tempo-s3-access-secret` from NooBaa bucket credentials, S3 CA bundle `ConfigMap`, TLS secret, `TempoStack`, and `UIPlugin`
  - Kiali: `ClusterRoleBinding` and `Kiali` CR
  - Observability: OSSM console plugin, Istio proxy `PodMonitor`, istiod `ServiceMonitor`, and `Telemetry` resource

**`servicemesh-ingress`** — depends on `servicemesh-controlplane`. Deploys a standalone ingress gateway in the `istio-ingress` namespace: `Deployment`, `ServiceAccount`, `Service`, `HorizontalPodAutoscaler`, `NetworkPolicy`, `PodDisruptionBudget`, `Role`, and `RoleBinding`.
