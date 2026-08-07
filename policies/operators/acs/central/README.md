---
# ACS Central

## Description
Deploys the `Central` component of ACS on the hub, monitors its health, and manages the
full lifecycle of the cluster init-bundle certificates it issues (creation, expiry
detection, and automatic rotation).

## Dependencies
  - `acs-operator` (from [`../operator/`](../operator/)) must be Compliant

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_advanced_cluster_security_for_kubernetes/latest)

Notes:
  - Deployed to hub only, via the `ft-acs--hub` placement
  - Sensor secret propagation and `SecuredCluster` creation (hub and managed alike) live
    in [`../sensor/`](../sensor/), not here

## Implementation Details

**`acs-central`** — depends on `acs-operator` (a different `PolicyGenerator`; ACM resolves
policy `dependencies` by name/namespace at runtime regardless of which generator produced
them). Deploys the `Central` CR and a `ConsoleLink`. Includes an `InformOnly` health check
(`acs-central-status`) that uses `object-templates-raw` to verify all four Central
deployments (`central`, `central-db`, `scanner`, `scanner-db`) are fully available.

**`acs-central-init-bundle`** — depends on `acs-central`. Runs a `Job` (backed by a
`ServiceAccount`, `Role`, and `RoleBinding`) that calls the ACS API to generate an
init-bundle and writes the resulting TLS secrets to the `stackrox` namespace.

**`acs-central-init-bundle-cert`** — depends on `acs-central-init-bundle`. Uses a
`CertificatePolicy` to monitor `sensor-tls` expiry, plus a plain existence check
(`init-bundle/init-bundle-tls-secret.yml`, matched via `objectSelector` on
`certificate_key_name: sensor-cert.pem`) on the same secret to catch it being deleted
outright.

**`acs-central-expired-certs`** — depends on `acs-central-init-bundle-cert` being
**NonCompliant** (uses `ignorePending: true` to avoid always-pending state). Uses
`complianceType: mustnothave` with the same nameless `init-bundle-tls-secret.yml`, this
time matched via `objectSelector` on any secret with a `certificate_key_name` label
(`Exists`), to delete all three expired TLS secrets in one `ConfigurationPolicy` and reset
the init-bundle `Job`, triggering the bundle to be regenerated.
