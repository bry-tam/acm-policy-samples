# Cert-Manager Operator
Deploys the cert-manager Operator along with a sample `ClusterIssuer` making use of same CA certificate.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.14

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#cert-manager-operator-for-red-hat-openshift)

---
**Notes:**
  - `ClusterIssuer` is using a self-signed CA file.  Production environments should use an appropriate PKI
  - Policy configures cluster-monitoring to scrape cert-manager.  There are no rules or alerts, only the `ServiceMonitor` to scrape cert-manager
  - Configures cert-manager to include the cluster trusted-ca bundle.  This shouldn't hurt if you don't have a ca applied through the cluster-proxy.
  - Requires 2.14 to make use of the `fail` function when there are no deployments to cert-manager namespace.
