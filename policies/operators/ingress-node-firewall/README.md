# Ingress Node Firewall Operator

## Description
Installs the Ingress Node Firewall (INF) operator into the `openshift-ingress-node-firewall`
namespace. The operator uses eBPF XDP kernel programs to enforce stateless ingress firewall
rules at the node level, providing a lightweight alternative to network policies for
cluster-wide ingress traffic control.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html/networking_operators/ingress-node-firewall-operator)

Notes:
  - Targets clusters labeled `ingress-node-firewall=enabled` via the
    `ft-ingress-node-firewall--enabled` placement
  - The namespace requires `pod-security.kubernetes.io/enforce: privileged` because the
    operator deploys eBPF XDP programs that need elevated kernel access
  - Uses `upgradeApproval: Automatic` — pin `startingCSV` and `versions` to lock to a
    specific release
  - After installation, deploy an `IngressNodeFirewallConfig` CR in the operator namespace
    to activate the DaemonSet on target nodes, then create `IngressNodeFirewall` CRs to
    define firewall rules
  - `spec.ebpfProgramManagerMode` on the `IngressNodeFirewallConfig` is set to `true` when
    the ManagedCluster has the label `ebpf-manager=enabled`, otherwise `false`

## Firewall Rules

Rules are defined under `rules/` and are deployed as part of the `ingress-node-firewall-rules`
policy, which depends on the operator being Compliant. The eBPF LPM trie evaluates rules using
Longest Prefix Match, so more-specific CIDRs in an allow group always win over a catch-all deny.

### block-external-dns

Blocks inbound DNS queries (UDP/TCP port 53) from outside the cluster. Cluster-internal CIDRs
(pod network, service network, machine network) are allowed through; all other sources are denied.
The machine network is read from the original install-config stored in the `cluster-config-v1`
ConfigMap in `kube-system`.

Intended for clusters where CoreDNS runs on `hostNetwork` (e.g. Azure), which exposes the DNS
port directly on the node's external interface.

### block-icmp-timestamp

Blocks ICMP Timestamp Request (type 13) and Timestamp Reply (type 14) from all IPv4 sources.
Recommended by CIS Red Hat OpenShift hardening to prevent remote host discovery via ICMP
timestamp probing. ICMPv6 has no equivalent timestamp types and requires no additional rule.
