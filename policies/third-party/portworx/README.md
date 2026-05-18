---
# Portworx Operator

## Description
Deploys the Portworx certified storage operator into the `portworx` namespace and enables the OpenShift console plugin. This policy installs the operator only; a `StorageCluster` must be configured separately to provision Portworx storage.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [Portworx on OpenShift](https://docs.portworx.com/install-portworx/openshift/)

Notes:
  - Uses the `certified-operators` catalog source
  - Does not configure a `StorageCluster`; Portworx storage provisioning requires additional setup per environment

## Implementation Details

**`portworx-operator`** — creates the `portworx` namespace, installs the `OperatorPolicy`, and enables the Portworx console plugin via a `ConsolePlugin` patch.
