---
# Ansible Automation Platform Operator

## Description
Deploys the Ansible Automation Platform Operator and configures a full `AnsibleAutomationPlatform` instance including the Gateway, Controller, Hub, and EDA components. Uses ODF NooBaa S3 storage for the Hub component, constructing the bucket credentials dynamically at deploy time.

## Dependencies
  - [Data Foundation Operator](../data-foundation/) — ODF must be present for the NooBaa `ObjectBucketClaim`

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_ansible_automation_platform/latest/html-single/installing_on_openshift_container_platform/index)

Notes:
  - Deploys Ansible Platform Gateway along with Controller, Hub, and EDA components
  - Does not deploy Ansible AI

## Implementation Details

**`ansible-automation-operator`** — creates the `ansible-automation-platform` namespace and deploys the `OperatorPolicy`.

**`ansible-automation-configure`** — depends on `ansible-automation-operator`. Creates an `ObjectBucketClaim` for NooBaa S3 storage, copies the NooBaa S3 serving cert `ConfigMap`, then uses `object-templates-raw` to look up the resulting bucket credentials and construct the `ansible-hub-odf` `Secret` with the S3 endpoint, bucket name, and access keys. Finally deploys the `AnsibleAutomationPlatform` CR once the secret is ready.

**`ansible-automation-status`** — depends on `ansible-automation-configure`, runs `InformOnly`. Uses `object-templates-raw` to dynamically build health checks for all expected `Deployment` and `StatefulSet` resources. EDA and Hub deployments are conditionally included based on whether those components are enabled in the `AnsibleAutomationPlatform` spec.
