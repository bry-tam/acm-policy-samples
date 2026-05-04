---
# LogicMonitor

## Description
Deploys the LogicMonitor LM Container Helm chart via an ArgoCD Application into the `logicmonitor` namespace. The Helm chart is sourced directly from the LogicMonitor Helm repository and configured with the cluster name and a credentials Secret.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://www.logicmonitor.com/support/lm-container)
               [Install Docs](https://www.logicmonitor.com/support/installing-the-lm-container-helm-chart)
               [Helm Chart](https://artifacthub.io/packages/helm/logicmonitor-helm-charts/lm-container)
               [Helm Chart Git](https://github.com/logicmonitor/helm-charts/)

Notes:
  - Targets clusters labeled `logicmonitor=enabled` via the `ft-logicmonitor--enabled` placement
  - `secret-sample.yml` contains **fake placeholder credentials** — replace `account`, `accessID`, and `accessKey` with real values before deploying
  - In production, do not store credentials in this policy. Use a secrets management solution such as HashiCorp Vault with the External Secrets Operator to inject the `logicmonitor-credentials` Secret onto each cluster
  - The ArgoCD Application sets `lm.clusterName` from the managed cluster name automatically via hub template
