# Network Observability Operator
Installs the Network Observability Operator.

Note:
  - Requires Loki Operator to be installed


## Dependencies
  - [Loki Operator](../loki/generator.yml)
  - s3 Storage - Current configuration showcases using [ODF Operator](../data-foundation/)

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/network_observability/index)

---
**Notes:**
  - Configures LokiStack and FlowCollector
  - Dependent on s3 storage for Loki, example uses ODF
  - TODO: configure to showcase how to make use of prometheus instead of Loki
  - TODO: Configuration is incomplete, DaemonSets don't deploy with scc issues.  This is likely due to a change in the operator from when the policy was first implemented.
