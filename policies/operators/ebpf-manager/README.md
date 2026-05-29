# eBPF Manager Operator

## Description
Installs the eBPF Manager (bpfman) operator into the `bpfman` namespace. bpfman is a
system daemon for managing eBPF programs on cluster nodes, providing a centralized way to
load, unload, and inspect eBPF programs without requiring privileged containers.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking_operators/ebpf-manager-operator)

Notes:
  - Targets clusters labeled `ebpf-manager=enabled` via the `ft-ebpf-manager--enabled`
    placement — the same label used by the Ingress Node Firewall operator to enable
    `ebpfProgramManagerMode` on the `IngressNodeFirewallConfig`
  - The namespace requires `pod-security.kubernetes.io/enforce: privileged` because bpfman
    loads eBPF programs into the kernel
  - Uses `upgradeApproval: Automatic` — pin `startingCSV` and `versions` to lock to a
    specific release
