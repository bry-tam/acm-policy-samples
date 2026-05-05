---
# Chrony NTP

## Description
Applies a MachineConfig to the `worker` and `master` MachineConfigPools to configure chronyd with the standard Red Hat NTP pool servers (`[0-3].rhel.pool.ntp.org`), replacing any existing `/etc/chrony.conf` on cluster nodes.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/post-installation_configuration/post-install-machine-configuration-tasks#using-machineconfigs-to-change-the-chrony-time-service_post-install-machine-configuration-tasks)

Notes:
  - Targets all clusters in the ClusterSet including the hub via the `env-bound-placement` placement
  - Creates `99-worker-chrony` and `99-master-chrony` MachineConfigs; the `99-` prefix ensures they apply after default platform configs
  - The `/etc/chrony.conf` file is written via Ignition with `overwrite: true`, replacing any prior NTP configuration on the node
  - Applying this policy will trigger a rolling node reboot on each MachineConfigPool as the MCO reconciles the new config
