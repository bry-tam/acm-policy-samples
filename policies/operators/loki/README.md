# Loki Operator
Installs the Loki Operator

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest from Cluster Logging](https://docs.redhat.com/en/documentation/red_hat_openshift_logging/latest/html/installing_logging/installing-logging#install-loki-operator-cli_installing-logging)

---
**Notes:**
  - Does not configure an instance of LokiStack
  - Doc link goes to OpenShift Cluster Logging, Loki Operator does not have it's own docs.  Configuring an instance of `LokiStack` should follow documentation for the operator that is going to make uses of it, such as Logging or Network Observability.
