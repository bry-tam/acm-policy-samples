---
# Disable Self-Provisioner

## Description
Prevents authenticated users from self-provisioning new OpenShift projects by clearing the subjects from the `self-provisioners` ClusterRoleBinding and setting `rbac.authorization.kubernetes.io/autoupdate: "false"` to stop OpenShift from restoring it automatically.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/authentication_and_authorization/disabling-self-provisioning)

Notes:
  - Targets all clusters in the ClusterSet via the `env-bound-placement` placement
  - Uses `mustonlyhave` to enforce that `subjects` is empty — ACM will remove any subjects OpenShift re-adds
  - The `autoupdate: "false"` annotation prevents the OpenShift RBAC controller from repopulating the binding between ACM reconciliations
  - After applying, project creation must be delegated to a group or user explicitly via a separate ClusterRoleBinding
