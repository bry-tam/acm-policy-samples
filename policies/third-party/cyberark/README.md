---
# CyberArk

## Description
Deploys CyberArk Conjur OSS via an ArgoCD Application using the official CyberArk Helm chart, providing secrets management for workloads running on managed clusters.

## Dependencies
- ArgoCD (OpenShift GitOps) must be installed and the `openshift-gitops` namespace must exist
- The `cyberark` AppProject or `default` project must be configured in ArgoCD

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.cyberark.com/conjur-open-source/latest/en/content/get-started/quick-start-k8s.htm)

Notes:
  - Targets clusters labeled `cyberark=enabled` via the `ft-cyberark--enabled` placement
  - Update `conjur.account`, `conjur.applianceUrl`, `authenticators`, and `ssl.certificate` in `argocd-application.yml` with values appropriate for your environment before enforcing
  - The `clusterName` value is resolved at policy evaluation time using the hub template `{{hub $.ManagedClusterName hub}}`
  - `ignoreDifferences` is configured for Deployment replicas, ServiceAccount imagePullSecrets, and ClusterRole rules to prevent ArgoCD drift from OpenShift mutations
