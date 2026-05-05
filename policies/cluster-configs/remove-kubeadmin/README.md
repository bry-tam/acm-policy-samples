---
# Remove kubeadmin

## Description
Removes the `kubeadmin` Secret from the `kube-system` namespace, disabling the temporary bootstrap administrator account on all clusters.

## Dependencies
- An identity provider must be configured and verified working before this policy is enforced. Removing kubeadmin without a working IDP will lock all users out of the cluster.
- It is strongly recommended to add a `dependencies` entry in the generator pointing to the Policy that configures cluster OAuth identity providers, ensuring kubeadmin is only removed after the IDP policy is Compliant.

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/removing-kubeadmin)

Notes:
  - Targets clusters labeled `remove-kubeadmin=enabled` via `ft-remove-kubeadmin--enabled`
  - Uses `mustnothave` — ACM will delete the Secret if it exists
  - Verify IDP login works on each cluster before applying this policy
