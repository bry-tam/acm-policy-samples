# Workload Availability Operator
This operator is the combined Node Health Check, Self Node Remediation, Fence Agents Remediation, and  Machine Deletion Remediation

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/latest)

#### **Policy layout**
|File path    |Description              |
|-------------|-------------------------|
|./-operatorpolicy.yml|ACM `OperatorPolicy` defining how to install each operator|
|./node-remediation-console.yml|OCP Console plugin to add Node Remediation to the UI|
|./far-nhc-remediation|Example using NHC with FAR to taint nodes so workloads reschedule quickly and MDO to recreate the node|
|./snr-nhc-remediation|Example using NHC with SNR to recover the workloads and MDO to recreate the node|

---
**Notes:**
  -
