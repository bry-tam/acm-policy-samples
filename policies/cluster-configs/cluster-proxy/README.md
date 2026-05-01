#  Cluster Proxy

## Description
Manages the cluster-wide HTTP proxy configuration and trusted CA bundle. The proxy settings are
often established at install time but may need to be updated as certificates rotate or proxy
infrastructure changes. Replace the root CA in `example-root-ca.yml` with your organization's
specific CA bundle before deploying.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking/index#configuring-a-proxy)

Notes:
  - When rotating the CA, keep the old certificate alongside the new one so both are trusted during the transition period
  - The `Proxy` object references the CA ConfigMap by name (`bry-tam-ca`); update both files together when changing the CA name
  - Deployed to all clusters via `env-bound-placement`

## Implementation Details
Two resources are managed:

**`proxy-ca-configmap`** — a `ConfigMap` named `bry-tam-ca` in `openshift-config` containing the
PEM-encoded CA bundle under the `ca-bundle.crt` key. OpenShift distributes this bundle to all nodes
and injects it into pods that need to trust the proxy's TLS certificate. The file
`example-root-ca.yml` contains a self-signed example — replace the certificate data and ConfigMap
name with your organization's CA before use.

**`cluster-proxy`** — the `Proxy` singleton (`config.openshift.io/v1`) that sets the cluster-wide
proxy configuration. The `spec.trustedCA.name` field references the ConfigMap above. Add
`httpProxy`, `httpsProxy`, and `noProxy` fields to `proxy.yml` as needed for your environment.
