#  Ingress Renew Default Certificate

## Description
Monitors the expiry of the default OpenShift ingress router certificates and automatically rotates
them by deleting the router secrets when they approach expiration. Deleting the secrets causes
OpenShift to regenerate them, and the router pods are then restarted to pick up the new certificates.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/networking/index#nw-ingress-controller-configuration-parameters_configuring-ingress)

Notes:
  - Applied only to clusters labeled `renew-default-certs=enabled` via the `ft-renew-default-certs--enabled` placement
  - The `CertificatePolicy` monitors secrets with label `certificate_name: openshift-ingress` in the `openshift-ingress` and `openshift-ingress-operator` namespaces
  - Rotation is triggered when a certificate's remaining validity falls below 750 hours (~31 days)
  - `ignorePending: true` prevents the policy from reporting as Pending when the `CertificatePolicy` dependency is NonCompliant — NonCompliant is the expected trigger state

## Implementation Details
The policy uses a staged approach to label, detect, delete, and restart:

**Step 1 — Label secrets for monitoring:**
- `label-router-ca-secret` — adds `certificate_name: openshift-ingress` to the `router-ca` secret in `openshift-ingress-operator` (only if the secret exists)
- `label-router-certs-default-secret` — adds the same label to the `router-certs-default` secret in `openshift-ingress`

Both use `object-templates-raw` to skip labeling if the secret does not yet exist, preventing false NonCompliant states during initial rollout.

**Step 2 — Monitor expiry:**
- `default-ingress-certificates` (`CertificatePolicy`) — watches all secrets labeled `certificate_name: openshift-ingress` in both namespaces and reports NonCompliant when any certificate expires within 750 hours.

**Step 3 — Rotate secrets** ← triggers when `CertificatePolicy` is NonCompliant:
- `router-ca-secret` (`mustnothave`) — deletes the `router-ca` secret, causing OpenShift to regenerate the router CA
- `router-certs-default-secret` (`mustnothave`) — deletes the `router-certs-default` secret, causing OpenShift to regenerate the default router certificate

Once deleted the secrets no longer exist, making both ConfigurationPolicies Compliant.

**Step 4 — Restart router pods** ← triggers when both delete steps are Compliant:
- `ingress-operator-pod` — patches the `ingress-operator` Deployment with a `restartedAt` annotation to trigger a rolling restart
- `default-router-pod` — patches the `router-default` Deployment with the same annotation
