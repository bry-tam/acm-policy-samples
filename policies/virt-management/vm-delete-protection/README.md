---
# VM Delete Protection

## Description
Ensures all VirtualMachines that are not explicitly labeled `admin-allow-delete` have the label `kubevirt.io/vm-delete-protection: "True"` set. A ValidatingAdmissionPolicy enforces that the protection label cannot be removed unless `admin-allow-delete` is present on the VM.

## Dependencies
- None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_virtualization/latest/html/virtual_machines/index)

Notes:
  - Targets clusters labeled `ocp-virt=enabled` via the `ft-ocp-virt--enabled` placement
  - The ConfigurationPolicy uses an `objectSelector` with `DoesNotExist` on `admin-allow-delete` to target only unexempted VMs, and a `namespaceSelector` that excludes `kube-*`, `openshift-*`, `open-*`, `default*`, `multicluster-engine`, and `hive` namespaces
  - Uses `musthave` so the label is added without disturbing other existing labels on the VM
  - The `ValidatingAdmissionPolicy` (VAP) blocks any UPDATE to a VirtualMachine that would remove `kubevirt.io/vm-delete-protection: "True"` unless the `admin-allow-delete` label is present on the updated object
  - To exempt a VM from delete protection, add the label `admin-allow-delete` with any value; the ConfigurationPolicy will no longer target it and the VAP will permit label removal
