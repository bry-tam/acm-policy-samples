# vmware-disk-alignment

## Description
Ansible playbook that scans every VM in a vCenter inventory, inspects each VMDK's provisioned capacity, and reports any disk whose size in bytes is not evenly divisible by 4096. Disks that are not aligned to a 4096-byte boundary can cause degraded performance or unexpected behavior on modern 4K-native (Advanced Format) storage.

## Dependencies
- Python: `pip install -r requirements.txt`
- Ansible collection: `ansible-galaxy collection install community.vmware`

## Details
ACM Minimal Version: N/A (standalone Ansible playbook, no ACM required)
Documentation: https://docs.ansible.com/ansible/latest/collections/community/vmware/vmware_guest_disk_info_module.html

Notes:
  - Run against `localhost`; the vCenter API is called directly from the control node via pyVmomi — no SSH to managed hosts required
  - Connection settings are supplied via a vars file (see [Usage](#usage)); environment variables (`VMWARE_HOST`, `VMWARE_USER`, `VMWARE_PASSWORD`) are used as fallbacks when vars are not passed on the command line
  - `vcenter_validate_certs` defaults to `false`; set to `true` in production
  - Optionally scope the scan with `vcenter_folder` (inventory folder path) and/or `vm_name` (single guest name); omit both to scan all VMs visible to the vCenter user
  - VMs that are temporarily inaccessible (e.g., powered off and locked) are skipped via `failed_when: false` and do not abort the run
  - A CSV report (`vmware-disk-alignment-report.csv`) is written to the playbook directory when misaligned disks are found

## Implementation details (Optional)

### Why 4096?

Modern SSDs and NVMe drives use 4096-byte (4K) physical sectors. VMware exposes disks to guests as 512-byte logical sectors by default, but the underlying storage stack still reads and writes in 4K pages. A VMDK whose total capacity is not a multiple of 4096 bytes means the final partial page is never fully utilised, which can surface as:

- Wasted space on thin-provisioned datastores
- Write amplification on all-flash arrays that enforce 4K alignment
- Unexpected behavior when migrating VMDKs to a 4Kn (4K-native) datastore

### How the math works

`vmware_guest_disk_info` returns `capacity_in_kb` as an integer. One kilobyte is 1024 bytes, so:

```
capacity_in_bytes = capacity_in_kb × 1024
capacity_in_bytes % 4096 == 0  ⟺  capacity_in_kb % 4 == 0
```

The playbook uses Jinja2's built-in `divisibleby` test:

```yaml
| rejectattr('value.capacity_in_kb', 'divisibleby', 4)
```

This keeps only disks where `capacity_in_kb % 4 != 0`, i.e., those not evenly divisible by 4096 bytes.

### Usage

1. Install Python and Ansible dependencies:

```bash
pip install -r requirements.txt
ansible-galaxy collection install community.vmware
```

2. Copy the example vars file and edit it with your vCenter connection details:

```bash
cp vars.example.yml vars.yml
# edit vars.yml — set vcenter_hostname, vcenter_username, and vcenter_password
# optionally set vcenter_folder and/or vm_name to limit the scan scope
```

3. Run the playbook, passing the vars file with `-e @`:

```bash
ansible-playbook vmware-disk-alignment.yml -e @vars.yml
```

Keep `vars.yml` local and out of version control if it contains real credentials. To avoid storing the password in the file, leave `vcenter_password` unset in `vars.yml` and pass it at runtime:

```bash
ansible-playbook vmware-disk-alignment.yml -e @vars.yml -e vcenter_password=secret
```

To scan a subset of VMs, uncomment and set the optional scope vars in `vars.yml`:

```yaml
vcenter_folder: "/Datacenter/vm/Production"
vm_name: "my-app-vm"
```

`vcenter_folder` limits inventory to VMs under that folder path; `vm_name` further restricts to one guest. Either can be used alone. Omit both to scan every VM the vCenter account can see.

Alternatively, set `VMWARE_HOST`, `VMWARE_USER`, and `VMWARE_PASSWORD` in the environment and run without a vars file — the playbook reads those when connection vars are not supplied via `-e`.

### Example output

```
TASK [FAIL — misaligned VMDK found] *******************************
ok: [localhost] => (item=old-db-vm / Hard disk 2) => {
    "msg": "VM:     old-db-vm\nDisk:   Hard disk 2\nVMDK:   [ds-ssd] old-db-vm/old-db-vm_1.vmdk\nSize:   10485761 KB\n        (10.0 GB)\nOffset: 1024 bytes past\n        the last 4096-byte boundary\n"
}

TASK [Summary] ****************************************************
ok: [localhost] => {
    "msg": "SUMMARY: 1 VMDK(s) across 1 VM(s) have capacity not evenly divisible by 4096 bytes."
}
```

