---
# Workload Availability Operator

## Description
Deploys Node Health Check (NHC), Self Node Remediation (SNR), Fence Agents Remediation (FAR), and Machine Deletion Remediation (MDR) operators into the `openshift-workload-availability` namespace. Configures an example `NodeHealthCheck` and remediation templates to automatically recover workloads from unhealthy nodes.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/workload_availability_for_red_hat_openshift/latest)

## Implementation Details

**`workload-availability-operator`** — creates the `openshift-workload-availability` namespace and installs four `OperatorPolicy` resources for FAR, SNR, NHC, and MDR. Also enables the Node Remediation console plugin (gated via `extraDependencies` on the NHC `OperatorPolicy` being compliant).

**`workload-availability-remediation`** — depends on `workload-availability-operator`. Deploys one of two mutually exclusive remediation configurations (switch by commenting/uncommenting in the generator):

  - **SNR variant** (`snr-nhc-remediation/`, enabled by default): `NodeHealthCheck` that triggers SNR via an out-of-service taint template, followed by MDR to recreate the node via `MachineDeleton` template.
  - **FAR variant** (`far-nhc-remediation/`, commented out): `NodeHealthCheck` that triggers FAR to fence the node, then MDR to recreate it.
