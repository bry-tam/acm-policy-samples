---
# Builds for Red Hat OpenShift Operator

## Description
Deploys the Builds for Red Hat OpenShift Operator into the `openshift-builds` namespace, providing `OpenshiftBuild`/`ShipwrightBuilds` resources for building and managing container images directly on the cluster via Shipwright.

## Dependencies
  - Requires the Red Hat OpenShift Pipelines Operator to already be installed on the cluster (see `../tekton/`, which installs it in this repo). The `openshift-builds-operator` policy declares a `dependencies:` entry on the `tekton-operator` policy (`compliance: Compliant`), so this policy will not attempt to install Builds until the Pipelines Operator policy is `Compliant` on the cluster. Ensure the `ft-tekton--enabled` placement also targets any cluster this policy is enabled on, otherwise the dependency will never resolve.

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/builds_for_red_hat_openshift/latest)

Notes:
  - Installs the operator only; no `OpenshiftBuild`/`ShipwrightBuilds` instance is configured here — OLM creates the default `cluster` instance automatically once the operator is running
  - Pinned to `channel: builds-1.9` to track the 1.9 release line; switch to `latest` to always track the most recent stable release instead
  - Uses `upgradeApproval: Automatic`

## Implementation Details

**`openshift-builds-operator`** — creates the `openshift-builds` namespace (installation mode AllNamespaces, so no `targetNamespaces` is set on the `OperatorGroup`) and installs the `OperatorPolicy`.
