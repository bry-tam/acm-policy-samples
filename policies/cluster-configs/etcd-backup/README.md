#  etcd Backup

## Description
Deploys an automated etcd backup solution as a `CronJob` running on a schedule and writing
etcd snapshots to a `PersistentVolumeClaim`. All supporting RBAC and storage resources are
created in a dedicated `etcd-infra` namespace.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/backup_and_restore/index#backup-etcd)

Notes:
  - Deployed to all clusters via `env-bound-placement`
  - Template processing is disabled (`disable-templates: "true"`) to prevent ACM from interpreting Go template syntax in the CronJob spec
  - The `CronJob` runs every 10 minutes by default; adjust `spec.schedule` in `cronjob.yml` to fit your RPO requirements
  - The PVC is provisioned with 10Gi `ReadWriteOnce`; resize in `persistentvolumeclaim.yml` as needed
  - The `etcd-infra` namespace is created with an empty `node-selector` annotation so the backup pod can run on any node

## Implementation Details
All resources are deployed into the `etcd-infra` namespace:

| Manifest | Resource | Purpose |
|---|---|---|
| `namespace.yml` | `Namespace` `etcd-infra` | Isolated namespace with empty node selector |
| `serviceaccount.yml` | `ServiceAccount` `etcd-backup` | Identity for the backup pod |
| `role.yml` | `ClusterRole` `etcd-privileged` | Grants `use` on the `node-exporter` SCC, allowing the backup pod to run with host access |
| `rolebinding.yml` | `ClusterRoleBinding` `etcd-privileged` | Binds the ClusterRole to the `etcd-backup` ServiceAccount |
| `persistentvolumeclaim.yml` | `PersistentVolumeClaim` `etcd-backup` | 10Gi RWO volume for storing snapshots |
| `configmap.yml` | `ConfigMap` `etcd-backup-scripts` | Shell scripts copied into the backup pod at runtime |
| `cronjob.yml` | `CronJob` `etcd-backup` | Scheduled job (`*/10 * * * *`) that executes the backup scripts |

The backup pod runs as a privileged container on a master node, copies the backup scripts from
the `ConfigMap` into the host filesystem, then invokes the OCP `cluster-backup.sh` script to
produce an etcd snapshot, which is written to the mounted PVC.
