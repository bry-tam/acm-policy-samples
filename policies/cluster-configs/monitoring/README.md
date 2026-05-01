#  Cluster Monitoring

## Description
Configures OpenShift cluster monitoring and user-workload monitoring, with MCOA and non-MCOA
variants. The MCOA variant uses hub-side templates to read connection details set by the ACM
Observability policy on the `ManagedCluster` object. Only one variant should be active at a
time — toggle the commented manifests in `generator.yml`.

## Dependencies
  - [ACM Observability](../../acm-configs/observability/) — the MCOA variant depends on
    `ManagedCluster` annotations (`hub-cluster-id`, `hub-alertmanager-url`) set by the
    ACM Observability policy on the hub

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/monitoring/index)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - The MCOA variant is the default; swap in the non-MCOA manifests in `generator.yml` when MCOA is not deployed
  - The MCOA variant uses hub-side templates and conditionally adds alertmanager federation only when the `hub-cluster-id` annotation is present on the `ManagedCluster`
  - The non-MCOA variant reads the `hub-info-secret` on the managed cluster — this secret is only present when the observability addon is active
  - Both variants place all monitoring components (Prometheus, Alertmanager, Thanos) on infra nodes when available, falling back to worker nodes

## Implementation Details
Two pairs of manifests are provided — only one pair is active at a time:

**MCOA variant** (`cluster-monitoring-config-mcoa.yml` / `user-workload-monitoring-config-mcoa.yml`):
- Uses hub-side templates (`{{hub ... hub}}`) to read `ManagedCluster` annotations set by the
  ACM Observability policy (`hub-cluster-id`, `hub-alertmanager-url`)
- Conditionally adds `additionalAlertmanagerConfigs` to both `prometheusK8s` and the
  user-workload `prometheus` only when the `hub-cluster-id` annotation is present, pointing at
  the hub alertmanager with TLS and bearer token credentials derived from those annotations

**Non-MCOA variant** (`cluster-monitoring-config.yml` / `user-workload-monitoring-config.yml`):
- Uses managed-cluster-side Go templates (`{{- ... }}`) with an embedded hub template to detect
  whether the cluster is the local hub
- Reads the `hub-info-secret` from `open-cluster-management-addon-observability` (or
  `open-cluster-management-observability` on the hub) to determine whether observability is
  enabled and to extract the hub alertmanager URL and cluster ID
- When the secret is present, adds `additionalAlertmanagerConfigs` pointing at the hub
  alertmanager with TLS and bearer token credentials from secrets written by the observability addon
- Set to `InformOnly` in the generator comments as a safer default when the addon secret may not exist

Both variants:
- Place `alertmanagerMain`, `prometheusK8s`, `prometheusOperator`, `kubeStateMetrics`,
  `openshiftStateMetrics`, `telemeterClient`, and `thanosQuerier` on infra nodes when
  `hasNodesWithExactRoles "infra"` is true, otherwise on worker nodes
- Set `externalLabels` with `instance_name`, `managed_cluster`, and `product` derived from
  cluster claims and the `Infrastructure` object
- Configure 100 GiB `gp3-csi` PVCs and 7-day retention for Prometheus and Thanos Ruler
- Enable user-workload monitoring (`enableUserWorkload: true`)
