# Service Mesh 3.x Operator
Installs the ServiceMesh Operator.

## Dependencies
  - [OpenTelemetry Operator](../opentelemetry/)
  - [Tempo Operator](../tempo/)
  - s3 Storage - Current configuration showcases using [ODF Operator](../data-foundation/)
  - [Kiali Operator](../kiali/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_openshift_service_mesh/latest)

---
**Notes:**
  - Requires OpenTelemetry, Tempo, Kiali and s3 storage
  - Configuration makes use of ODF for storage requirements
  - Configures istio ingress gateway in istio-ingress namespace
  - Configures Tempo tracking in tracing-system namespace
  - Configures metrics for mesh control plane
  - TODO: Configure health policy to monitor SM is healthy
