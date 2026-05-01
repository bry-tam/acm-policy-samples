---
# Red Hat Developer Hub Operator

## Description
Deploys the Red Hat Developer Hub (Backstage) Operator and configures a `Backstage` instance connected to all ACM managed clusters. Each managed cluster is registered in Developer Hub using a `ManagedServiceAccount` token, enabling the software catalog to discover and surface resources from across the fleet.

## Dependencies
  - [Managed ServiceAccount](../../acm-configs/managedserviceaccount/) — the `enable-managed-serviceaccount` policy must be compliant before MSA resources are created

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/red_hat_developer_hub/latest)

Notes:
  - Operator install is validated; `Backstage` configuration likely needs site-specific tuning before production use
  - No health check for `Backstage` is currently included
  - `hub-template-auth/` deploys the `ServiceAccount` and `ClusterRoleBinding` required for hub-side templates to read cluster data when building the Developer Hub configuration

## Implementation Details

**`developer-hub-operator`** — installs the `OperatorPolicy` on clusters with `developer-hub=enabled`. No namespace is created here; the operator manages its own namespace.

**`developer-hub-acm-msa`** — runs on the hub (`ft-acm-hub--active`), depends on `enable-managed-serviceaccount`. Uses `object-templates-raw` to iterate all `ManagedCluster` resources and create a `ManagedServiceAccount` named `rhdh-<cluster-name>` in each cluster's namespace, providing Developer Hub with per-cluster API tokens.

**`developer-hub-configure`** — depends on `developer-hub-operator`. Uses `hubTemplateOptions.serviceAccountName: rhdh-hub-serviceaccount` for hub-template access. Creates the `developer-hub` namespace, deploys the `Backstage` CR, then (via `extraDependencies` on `Backstage` being compliant) applies the app config `ConfigMap` (using `object-templates-raw` to read the hub Backstage route and inject cluster tokens) and the dynamic plugins `ConfigMap`.
