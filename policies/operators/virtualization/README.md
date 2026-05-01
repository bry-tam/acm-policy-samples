---
# OpenShift Virtualization Operator

## Description
Deploys the OpenShift Virtualization Operator into the `openshift-cnv` namespace and configures a `HyperConverged` instance with live migration enabled over a dedicated network interface (`bond3.999`). The namespace is labeled for cluster monitoring so virtualization metrics are scraped by Prometheus.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/virtualization/index)

Notes:
  - Targets clusters labeled `ocp-virt=enabled` via the `ft-ocp-virt--enabled` placement
  - Namespace is labeled `openshift.io/cluster-monitoring: "true"` to enable Prometheus scraping
  - Live migration limits: 5 parallel migrations per cluster, 2 outbound per node, 150 s progress timeout, 800 s completion timeout per GiB

## Implementation Details

**`openshift-virtualization`** — creates the `openshift-cnv` namespace with cluster monitoring enabled, installs the `OperatorPolicy` with a namespace-scoped `OperatorGroup`, then deploys the `HyperConverged` CR (gated via `extraDependencies` on the `OperatorPolicy` being compliant) with live migration configured to use `bond3.999` as the dedicated migration network.
