#  Ingress

## Description
Manages the default OpenShift `IngressController` configuration and the TLS certificate served
by the default router. Two policies work together: `ocp-ingress-infra` places ingress pods on
infra nodes when available and sets the replica count accordingly, and `ingress-certificate`
issues a cert-manager `Certificate` for the ingress domain and applies it to the `IngressController`.

## Dependencies
  - [CA ClusterIssuer](../../operators/cert-manager/ca-clusterissuer/) — the `cert-manager-clusterissuer` policy must be Compliant before the certificate policy runs

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking/index#nw-ingress-controller-configuration-parameters_configuring-ingress)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - `ingress-cert-ready` is `InformOnly` and must be Compliant before `ingress-default-certs` is applied
  - Replica count is capped at 3 when 3 or more infra nodes are present; defaults to 2 on worker nodes
  - The certificate DNS names cover both the bare ingress domain and the wildcard (`*.apps.cluster.domain`)

## Implementation Details
**`ocp-ingress-infra`** — a template checks for infra nodes using `hasNodesWithExactRoles "infra"`.
If present, the `IngressController` is configured with `node-role.kubernetes.io/infra` as the
node selector and the matching toleration. If not, it falls back to `node-role.kubernetes.io/worker`
with no tolerations. The replica count is set to `min(infra node count, 3)` or `2` when no infra
nodes exist.

**`ingress-certificate`** applies three manifests in sequence:

1. **`ingress-certificate`** — creates a cert-manager `Certificate` in `openshift-ingress`.
   The DNS names are read from the `IngressController` status domain, covering both the apex
   and wildcard subdomains. The certificate is issued by `ca-clusterissuer` into secret
   `ingress-cert-tls`.

2. **`ingress-cert-ready`** (`InformOnly`) — verifies that all conditions on the `Certificate`
   have `status: True`, gating the next step without making any changes itself.

3. **`ingress-default-certs`** ← depends on `ingress-cert-ready` Compliant — patches the
   `IngressController` `defaultCertificate` to reference `ingress-cert-tls`, activating the
   custom certificate on the default router.
