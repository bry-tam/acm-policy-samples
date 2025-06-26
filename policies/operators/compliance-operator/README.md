# Compliance Operator
Installs the OpenShift Compliance Operator.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/compliance-operator#compliance-operator-installation)

---
**Notes:**
  - Requires configuring `ScanSetting` and `ScanSettingBinding`.  Example for nerc-cip profile included in policy.
  - Usability imporved when combined with ACS
  - Requires the namespace to have privileged pod-security label
