#  API Server Certificate

## Description
Configures a custom named certificate on the OpenShift API server using a cert-manager `Certificate`
resource. Waits for the certificate to be ready before patching the `APIServer` named-certificate
reference, ensuring the API server is never updated with a certificate that has not yet been issued.

## Dependencies
  - [CA ClusterIssuer](../../operators/cert-manager/ca-clusterissuer/) — the `cert-manager-clusterissuer` policy must be Compliant before this policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#api-server-certificates)

Notes:
  - The API server hostname is read dynamically from the `Infrastructure` cluster object
  - Certificate is issued into the `openshift-config` namespace as secret `apiserver-cert-tls`
  - `cert-ready.yml` runs as `InformOnly` and must be Compliant before the `APIServer` patch is applied

## Implementation Details
Three manifests are applied in sequence using `extraDependencies`:

1. **`apiserver-certificate`** — creates a cert-manager `Certificate` in `openshift-config`. The DNS
   name is derived from the cluster API URL by stripping the `https://` prefix and `:6443` suffix.
   The certificate references `ca-clusterissuer` as the `ClusterIssuer`.

2. **`apiserver-cert-ready`** (`InformOnly`) — checks that all conditions on the `Certificate` have
   `status: True`. This gates the next step without enforcing any changes itself.

3. **`apiserver-named-certs`** — patches the `APIServer` singleton to add a `namedCertificates`
   entry mapping the API server hostname to the `apiserver-cert-tls` secret. Only applied once
   `apiserver-cert-ready` is Compliant, preventing the API server from referencing a secret that
   does not yet exist.
