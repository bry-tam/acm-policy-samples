#  etcd Encryption

## Description
Enables encryption of etcd data at rest using `aescbc` by setting `spec.encryption.type` in the
`APIServer` cluster CR. Three `InformOnly` health-check policies gate on the enforce step being
Compliant and then verify that each API server component (`KubeAPIServer`, `Authentication`,
`OpenShiftAPIServer`) has completed its encryption rollout.

## Dependencies
  - None

## Details
ACM Minimal Version: 2.12

Documentation: [latest](https://docs.redhat.com/en/documentation/openshift_container_platform/latest/html-single/security_and_compliance/index#encrypting-etcd)

Notes:
  - Applied only to clusters labeled `etcd-encryption=encrypt` via the `ft-etcd-encryption--encrypt` placement
  - Encryption rollout is asynchronous; the health checks will remain NonCompliant until each component finishes re-encrypting its data
  - All three health manifests depend on `etcd-encryption` being Compliant before they evaluate

## Implementation Details
The policy enforces one resource and monitors three:

**`etcd-encryption`** (enforce) — patches the `APIServer` singleton to set
`spec.encryption.type: aescbc`. OpenShift then begins a rolling re-encryption of all etcd data
across the `KubeAPIServer`, `OpenShiftAPIServer`, and `Authentication` operators. This process
can take several minutes to hours depending on the amount of data stored.

The three `InformOnly` health checks each verify that the corresponding operator has set an
`Encrypted` condition with `status: "True"` and `reason: EncryptionCompleted`:

| Manifest | Resource checked | Operator |
|---|---|---|
| `health/kubeapiserver.yml` | `KubeAPIServer/cluster` | Core Kubernetes API |
| `health/oauthapiserver.yml` | `Authentication/cluster` | OAuth / OpenShift auth API |
| `health/openshiftapiserver.yml` | `OpenShiftAPIServer/cluster` | OpenShift API extensions |

All three health checks use `extraDependencies` on the `etcd-encryption` ConfigurationPolicy so
they do not evaluate until encryption has been requested. The policy is NonCompliant until all
three operators report `EncryptionCompleted`.
