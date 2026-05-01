---
# Compliance Operator

## Description
Deploys the OpenShift Compliance Operator and configures example `ScanSetting` and `ScanSettingBinding` resources for the `nerc-cip` and `cis` profiles. The operator scans cluster nodes and the API server against the selected compliance profiles and reports results as `ComplianceCheckResult` objects.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/compliance-operator#compliance-operator-installation)

Notes:
  - The `openshift-compliance` namespace requires the `privileged` pod-security label, included in `namespace.yml`
  - Example scans use `autoApplyRemediations: false`; enable with caution as remediations can affect cluster behaviour
  - Scan results are surfaced in the ACS console when ACS is also deployed

## Implementation Details

**`compliance-operator`** — creates the `openshift-compliance` namespace and installs the `OperatorPolicy`.

**`compliance-operator-example`** — deploys two `ScanSetting` / `ScanSettingBinding` pairs:
  - `nerc-cip` profile: extended NIST-based profile for energy-sector compliance
  - `cis` profile: CIS Kubernetes benchmark
