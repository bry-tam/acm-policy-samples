---
# Migration Toolkit for Virtualization Operator

## Description
Deploys the Migration Toolkit for Virtualization (MTV) Operator into the `openshift-mtv` namespace and creates a `ForkliftController` instance to enable VM migration from external hypervisors (VMware, oVirt, OpenStack) to OpenShift Virtualization.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/migration_toolkit_for_virtualization/latest)

Notes:
  - Targets clusters labeled `ocp-virt=enabled` via the `ft-ocp-virt--enabled` placement
  - Namespace is labeled `openshift.io/cluster-monitoring: "true"` to enable Prometheus scraping of MTV metrics

## Implementation Details

**`migration-toolkit-for-virtualization`** — creates the `openshift-mtv` namespace with cluster monitoring enabled, installs the `OperatorPolicy` with a namespace-scoped `OperatorGroup`, then deploys the `ForkliftController` CR (gated via `extraDependencies` on the `OperatorPolicy` being compliant).
